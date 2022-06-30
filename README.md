# ElasticAutocomplete

![](https://img.shields.io/github/license/liao2000/flutter_elastic_autocomplete?style=flat-square) ![](https://img.shields.io/github/issues/liao2000/flutter_elastic_autocomplete?color=orange&style=flat-square) ![](https://img.shields.io/github/stars/liao2000/flutter_elastic_autocomplete?color=blue&logo=github&style=flat-square)

ElasticAutocomplete is a widget combines `Autocomplete` and `Localstorage`.

![](https://i.imgur.com/kUHwLxr.png)

## Features

+ Create a custom `TextField`, which `Autocomplete` can't do.
+ It it easy to handle the list of options by `ElasticAutocompleteController`.
    + You can store data in `localstorage` which keeps data until user clean it.
    + You can store data in `memory` (like session storage) which keeps data until the program terminates.
    + You can use case-sensitive mode or case-insensitive mode.

## Usage

### Example without controller

+ You can control the list of options by `optionsBuilder`.
+ Besides, you can decorate `TextFormField` in `fieldViewBuilder` by yourself.

```dart
ElasticAutocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
        }
        const List<String> candidates = [
            "app",
            "bar",
            "car"
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
            // You must set controller, focusNode, and onFieldSubmitted 
            // in the textFormField
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
                onFieldSubmitted();
            },
            decoration: const InputDecoration(
            border: OutlineInputBorder(),
        ));
    });
```

### Example with controller

+ It is easy to use `ElasticAutocompleteController` to load and set the list of options.
+ You can set case sensitive or case insensitive in `ElasticAutocompleteController` to effect `optionBuilder` that generated by controller automatically. Default is case sensitive.
+ `ElasticAutocompleteController` does not need to be disposed.

```dart
class MyWidgetState extends State<MyWidget> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode _node;
  late ElasticAutocompleteController<String> _elasticAutocompleteCtrl;
  late TextEditingController _textEditingCtrl;

  @override
  void initState() {
    _node = FocusNode();
    _textEditingCtrl = TextEditingController();
    _elasticAutocompleteCtrl =
        ElasticAutocompleteController(id: 'name', caseSensitive: false);
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
            ElasticAutocomplete<String>(
                controller: _elasticAutocompleteCtrl,
                // use optionsBuilder which is generated by controller
                optionsBuilder: _elasticAutocompleteCtrl.optionsBuilder,
                // use textEditingCtrl to get values in the TextFormField.
                textEditingController: _textEditingCtrl,
                // when setting the textEditingController, set the focusNode simultaneously.
                focusNode: _node,
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    void Function() onFieldSubmitted) {
                  // design field view by yourself
                  return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ));
                }),
            ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    String val = _textEditingCtrl.text;
                    _textEditingCtrl.clear();
                    await _elasticAutocompleteCtrl.store(val);
                    print(val);
                  }
                },
                child: const Text("send")),
            ElevatedButton(
              onPressed: () {
                _elasticAutocompleteCtrl.clear();
              },
              child: const Text("clear"),
            ),
          ],
        ));
  }
}
```
