import 'package:flutter/material.dart';
import 'package:elastic_autocomplete/elastic_autocomplete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Scrollbar(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Center(
                  child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Example1(),
                    Example2(),
                  ],
                ),
              ))),
        ));
  }
}

class Example1 extends StatefulWidget {
  const Example1({Key? key}) : super(key: key);

  @override
  State<Example1> createState() => Example1State();
}

class Example1State extends State<Example1> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text(
              'Example1: set options in advance.',
              style: TextStyle(fontSize: 18),
            )),
        ElasticAutocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          const List<String> candidates = [
            "app",
            "bar",
            "car",
            "dot",
            "ear",
            "foo"
          ];
          return candidates.where((String option) {
            return option.contains(textEditingValue.text);
          });
        }, fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                void Function() onFieldSubmitted) {
          return TextFormField(
              autofocus: true,
              // You must set controller, focusNode, and onFieldSubmitted in the textFormField
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your favorite groups',
              ));
        }),
      ],
    );
  }
}

class Example2 extends StatefulWidget {
  const Example2({Key? key}) : super(key: key);

  @override
  State<Example2> createState() => Example2State();
}

class Example2State extends State<Example2> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode _node;
  late ElasticAutocompleteController _elasticAutocompleteCtrl;
  late TextEditingController _textEditingCtrl;

  @override
  void initState() {
    _node = FocusNode();
    _textEditingCtrl = TextEditingController();
    _elasticAutocompleteCtrl = ElasticAutocompleteController(id: 'name');
    super.initState();
  }

  @override
  void dispose() {
    _textEditingCtrl.dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Example2: store options after sending.',
                  style: TextStyle(fontSize: 18),
                )),
            ElasticAutocomplete(
                controller: _elasticAutocompleteCtrl,
                optionsBuilder: _elasticAutocompleteCtrl.optionsBuilder,
                textEditingController: _textEditingCtrl,
                focusNode: _node,
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    void Function() onFieldSubmitted) {
                  return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                      obscureText: false,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ));
                }),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    // store to the autocomplete
                    String val = _textEditingCtrl.text;

                    await _elasticAutocompleteCtrl.store(val);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(val)));
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text("send", style: TextStyle(color: Colors.white)),
                )),
          ],
        ));
  }
}
