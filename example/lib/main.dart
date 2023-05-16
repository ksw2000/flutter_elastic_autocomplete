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
      home: const MyHomePage(title: 'ElasticAutocomplete'),
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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Demo 1 build options without controller',
                          style: TextStyle(fontSize: 18),
                        )),
                    Example1(),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Demo 2 build options with controller',
                          style: TextStyle(fontSize: 18),
                        )),
                    Example2(),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Demo 3 customize text input field',
                          style: TextStyle(fontSize: 18),
                        )),
                    Example3(),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Demo 4 shares the same storage with demo2',
                          style: TextStyle(fontSize: 18),
                        )),
                    Example4(),
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
    return ElasticAutocomplete(
        optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text == '') {
        return const Iterable<String>.empty();
      }
      const List<String> options = [
        "app",
        "bar",
        "car",
        "dot",
        "ear",
        "foo",
        "god",
        "hop",
        "ice",
        "jam"
      ];
      return options.where((String option) {
        return option.contains(textEditingValue.text);
      });
    }, fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            void Function() onFieldSubmitted) {
      // Design field view by yourself
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
          ));
    });
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
  late ElasticAutocompleteController<String> _elasticAutocompleteCtrl;
  late TextEditingController _textEditingCtrl;

  @override
  void initState() {
    _node = FocusNode();
    _textEditingCtrl = TextEditingController();
    _elasticAutocompleteCtrl =
        ElasticAutocompleteController(id: 'example2', caseSensitive: false);
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
            ElasticAutocomplete(
              controller: _elasticAutocompleteCtrl,
              // use optionsBuilder which is generated by controller
              optionsBuilder: _elasticAutocompleteCtrl.optionsBuilder,
              fieldViewBuilder: _elasticAutocompleteCtrl.fieldViewBuilder(
                  decoration: const InputDecoration(
                border: OutlineInputBorder(),
              )),
              // use textEditingCtrl to get values in the TextFormField.
              textEditingController: _textEditingCtrl,
              // when setting the textEditingController, set the focusNode simultaneously.
              focusNode: _node,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      String val = _textEditingCtrl.text;
                      _textEditingCtrl.clear();
                      await _elasticAutocompleteCtrl.store(val);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Append "$val" to the options')));
                    }
                  },
                  child:
                      const Text("send", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    _elasticAutocompleteCtrl.clear();
                  },
                  child: const Text("clear",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ));
  }
}

class Example3 extends StatelessWidget {
  const Example3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ElasticAutocompleteController ctrl = ElasticAutocompleteController(
        id: 'example3',
        initialOptions: ["apple", "banana", "cat", "dog", "elephant"],
        showTopKWhenInputEmpty: 3);
    return ElasticAutocomplete(
        controller: ctrl,
        optionsBuilder: ctrl.optionsBuilder,
        fieldViewBuilder: ctrl.fieldViewBuilder(
            cursorColor: Colors.green,
            style: const TextStyle(color: Colors.green),
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
                hintText: 'hint text')));
  }
}

class Example4 extends StatelessWidget {
  const Example4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ElasticAutocompleteController ctrl = ElasticAutocompleteController(
        // use the same id with example2
        id: 'example2');
    return ElasticAutocomplete(
        controller: ctrl,
        optionsBuilder: ctrl.optionsBuilder,
        fieldViewBuilder: ctrl.fieldViewBuilder(
            decoration: const InputDecoration(border: OutlineInputBorder())));
  }
}
