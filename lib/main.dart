import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClipboardTest());
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(600, 800);
    const minSize = Size(300, 400);
    win.size = initialSize;
    win.minSize = minSize;
    win.alignment = Alignment.center;
    win.title = "剪贴板测试程序 - 代码小风";
    win.show();
  });
}

class ClipboardTest extends StatelessWidget {
  const ClipboardTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const HomePage(title: '剪贴板读取测试 - 代码小风'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var contentWidgets = <Widget>[const Text("没有内容")];

  void _paste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard != null) {
      final reader = await clipboard.read();

      final readers = await Future.wait(
        reader.items.map((e) => ReaderInfo.fromReader(e)),
      );
      if (!mounted) {
        return;
      }

      buildWidgetsForReaders(context, readers, (widgets) {
        setState(() {
          contentWidgets = widgets;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(1
      //   // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text(widget.title),
      // ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: contentWidgets
            .intersperse(const SizedBox(height: 10))
            .toList(growable: false),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _paste,
        tooltip: '读取剪贴板',
        backgroundColor: const Color.fromARGB(255, 243, 243, 243),
        child: const Icon(Icons.paste),
      ),
    );
  }
}

class Expand extends SingleChildRenderObjectWidget {
  const Expand({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderExpanded();
}

class _RenderExpanded extends RenderProxyBox {
  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    final boxConstraints = constraints as BoxConstraints;
    super.layout(
        boxConstraints.tighten(
          width: boxConstraints.maxWidth,
          height: boxConstraints.maxHeight,
        ),
        parentUsesSize: parentUsesSize);
  }
}

void buildWidgetsForReaders(
  BuildContext context,
  Iterable<ReaderInfo> readers,
  ValueChanged<List<Widget>> onWidgets,
) {
  final widgets = Future.wait(
    readers.mapIndexed(
      (index, element) => _buildWidgetForReader(context, element, index),
    ),
  );
  widgets.then((value) => onWidgets(value));
}

class _PlatformFormat {
  final PlatformFormat format;
  final bool virtual;
  final bool synthesized;

  _PlatformFormat(
    this.format, {
    required this.virtual,
    required this.synthesized,
  });
}

class ReaderInfo {
  ReaderInfo._({
    required this.reader,
    required this.suggestedName,
    required List<_PlatformFormat> formats,
    this.localData,
  }) : _formats = formats;

  static Future<ReaderInfo> fromReader(
    DataReader reader, {
    Object? localData,
  }) async {
    final List<String> formats = reader.platformFormats;
    final List<String> rawFormats =
        await reader.rawReader!.getAvailableFormats();

    List<String> synthesizedByReader = List.of(formats)
      ..removeWhere((element) => rawFormats.contains(element));

    final virtual =
        await Future.wait(formats.map((e) => reader.rawReader!.isVirtual(e)));

    final synthesized = await Future.wait(formats.map((e) async =>
        await reader.rawReader!.isSynthesized(e) ||
        synthesizedByReader.contains(e)));

    return ReaderInfo._(
      reader: reader,
      suggestedName: await reader.getSuggestedName(),
      localData: localData,
      formats: formats
          .mapIndexed((index, element) => _PlatformFormat(
                element,
                virtual: virtual[index],
                synthesized: synthesized[index],
              ))
          .toList(growable: false),
    );
  }

  final DataReader reader;
  final String? suggestedName;
  final List<_PlatformFormat> _formats;
  final Object? localData;
}

Future<Widget> _buildWidgetForReader(
  BuildContext context,
  ReaderInfo reader,
  int index,
) async {
  final itemFormats = reader.reader.getFormats([
    ...Formats.standardFormats,
  ]);

  final futures =
      itemFormats.map((e) => _widgetForFormat(context, e, reader.reader));

  final widgets = await Future.wait(futures);
  final children = widgets
      .where((element) => element != null)
      .cast<_RepresentationWidget>()
      .toList(growable: true);

  final formats = <DataFormat>{};
  children.retainWhere((element) => formats.add(element.format));

  final nativeFormats = reader._formats.map((e) {
    final attributes = [
      if (e.virtual) 'virtual',
      if (e.synthesized) 'synthesized',
    ].join(', ');
    return attributes.isNotEmpty ? '${e.format} ($attributes)' : e.format;
  }).toList(growable: false);

  return _ReaderWidget(
    itemName: '数据项 $index',
    suggestedFileName: reader.suggestedName ?? '无',
    representations: children,
    nativeFormats: nativeFormats,
  );
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({
    required this.itemName,
    required this.suggestedFileName,
  });

  final String itemName;
  final String suggestedFileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey.shade100,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            itemName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text('(名字: $suggestedFileName)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                )),
          ),
        ],
      ),
    );
  }
}

class _FooterWidget extends StatelessWidget {
  const _FooterWidget({
    required this.nativeFormats,
  });

  @override
  Widget build(BuildContext context) {
    final formats = nativeFormats.join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.blueGrey.shade50,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: '格式信息: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: formats),
          ],
        ),
        style: TextStyle(fontSize: 11.0, color: Colors.grey.shade600),
      ),
    );
  }

  final List<String> nativeFormats;
}

class _ReaderWidget extends StatelessWidget {
  const _ReaderWidget({
    required this.itemName,
    required this.suggestedFileName,
    required this.representations,
    required this.nativeFormats,
  });

  final String itemName;
  final String suggestedFileName;
  final List<Widget> representations;
  final List<String>? nativeFormats;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderWidget(
              itemName: itemName, suggestedFileName: suggestedFileName),
          ...representations.intersperse(const SizedBox(height: 2)),
          if (nativeFormats != null) ...[
            const SizedBox(height: 2),
            _FooterWidget(nativeFormats: nativeFormats!),
          ]
        ],
      ),
    );
  }
}

extension IntersperseExtensions<T> on Iterable<T> {
  Iterable<T> intersperse(T element) sync* {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield element;
        yield iterator.current;
      }
    }
  }
}

extension _ReadValue on DataReader {
  Future<T?> readValue<T extends Object>(ValueFormat<T> format) {
    final c = Completer<T?>();
    final progress = getValue<T>(format, (value) {
      c.complete(value);
    }, onError: (e) {
      c.completeError(e);
    });
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }

  Future<Uint8List?>? readFile(FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = getFile(format, (file) async {
      try {
        final all = await file.readAll();
        c.complete(all);
      } catch (e) {
        c.completeError(e);
      }
    }, onError: (e) {
      c.completeError(e);
    });
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }
}

Future<_RepresentationWidget?> _widgetForImage(
  BuildContext context,
  FileFormat format,
  String name,
  DataReader reader,
) async {
  final scale = MediaQuery.of(context).devicePixelRatio;
  final image = await reader.readFile(format);
  if (image == null || image.isEmpty) {
    return null;
  } else {
    return _RepresentationWidget(
      format: format,
      name: 'Image ($name)',
      synthesized: reader.isSynthesized(format),
      virtual: reader.isVirtual(format),
      content: Container(
        padding: const EdgeInsets.only(top: 4),
        alignment: Alignment.centerLeft,
        child: Image.memory(
          image,
          scale: scale,
        ),
      ),
    );
  }
}

Future<_RepresentationWidget?> _widgetForFormat(
    BuildContext context, DataFormat format, DataReader reader) async {
  switch (format) {
    case Formats.plainText:
      final text = await reader.readValue(Formats.plainText);
      if (text == null) {
        return null;
      } else {
        // Sometimes macOS uses CR for line break;
        final sanitized = text.replaceAll(RegExp('\r[\n]?'), '\n');
        return _RepresentationWidget(
          format: format,
          name: '纯文本',
          synthesized: reader.isSynthesized(format),
          virtual: reader.isVirtual(format),
          content: Text(sanitized),
        );
      }
    case Formats.plainTextFile:
      if (!reader.isVirtual(format) && !reader.isSynthesized(format)) {
        return null;
      }
      final contents = await reader.readFile(Formats.plainTextFile);
      if (contents == null) {
        return null;
      } else {
        final text = utf8.decode(contents, allowMalformed: true);
        return _RepresentationWidget(
          format: format,
          name: 'Plain Text (utf8 file)',
          synthesized: reader.isSynthesized(format),
          virtual: reader.isVirtual(format),
          content: Text(text),
        );
      }
    case Formats.htmlText:
      final html = await reader.readValue(Formats.htmlText);
      if (html == null) {
        return null;
      } else {
        return _RepresentationWidget(
          format: format,
          name: 'HTML 代码',
          synthesized: reader.isSynthesized(format),
          virtual: reader.isVirtual(format),
          content: Text(html),
        );
      }
    case Formats.png:
      return _widgetForImage(context, Formats.png, 'PNG', reader);
    case Formats.jpeg:
      return _widgetForImage(context, Formats.jpeg, 'JPEG', reader);
    case Formats.gif:
      return _widgetForImage(context, Formats.gif, 'GIF', reader);
    case Formats.tiff:
      return _widgetForImage(context, Formats.tiff, 'TIFF', reader);
    case Formats.webp:
      return _widgetForImage(context, Formats.webp, 'WebP', reader);
    case Formats.uri:
    case Formats.fileUri:
      final fileUriFuture = reader.readValue(Formats.fileUri);
      final uriFuture = reader.readValue(Formats.uri);

      final fileUri = await fileUriFuture;
      if (fileUri != null) {
        return _RepresentationWidget(
          format: Formats.fileUri,
          name: '路径',
          synthesized: reader.isSynthesized(format),
          virtual: reader.isVirtual(format),
          content: Text(fileUri.toString()),
        );
      }
      final uri = await uriFuture;
      if (uri != null) {
        return _RepresentationWidget(
          format: Formats.uri,
          name: 'URI',
          synthesized: reader.isSynthesized(Formats.uri),
          virtual: reader.isVirtual(Formats.uri),
          content: _UriWidget(uri: uri),
        );
      }
      return null;
    default:
      return null;
  }
}

class _UriWidget extends StatelessWidget {
  const _UriWidget({
    required this.uri,
  });

  final NamedUri uri;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(uri.uri.toString()),
        if (uri.name != null)
          DefaultTextStyle.merge(
            style: TextStyle(color: Colors.grey.shade600),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name: '),
                Expanded(
                  child: Text(uri.name!),
                ),
              ],
            ),
          )
      ],
    );
  }
}

class _RepresentationWidget extends StatelessWidget {
  const _RepresentationWidget({
    required this.format,
    required this.name,
    required this.synthesized,
    required this.virtual,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final tag = [
      if (virtual) 'virtual',
      if (synthesized) 'synthesized',
    ].join(' ');
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(tag.isNotEmpty ? ' ($tag)' : ''),
              ],
            ),
            const SizedBox(
              height: 2,
            ),
            content,
          ],
        ),
      ),
    );
  }

  final DataFormat format;
  final String name;
  final bool synthesized;
  final bool virtual;
  final Widget content;
}
