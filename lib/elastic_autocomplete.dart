library elastic_autocomplete;

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';

/// A widget wraps `RawAutocomplete`.
class ElasticAutocomplete<T extends String> extends StatefulWidget {
  /// The user's text input is received in a field built with the
  /// [fieldViewBuilder] parameter. The options to be displayed are
  /// determined by [optionsBuilder]. If you want to use [focusNode] or
  /// [textEditingController]. you should define them two simultaneously.
  ///
  /// [textEditingController] and [initialValue] is used for [fieldViewBuilder].
  /// Notice that you cannot define the [textEditingController] and [initialValue]
  /// simultaneously.
  const ElasticAutocomplete({
    Key? key,
    this.maxHeight,
    required this.optionsBuilder,
    required this.fieldViewBuilder,
    this.controller,
    this.focusNode,
    this.onSelected,
    this.textEditingController,
    this.initialValue,
  })  : assert((focusNode == null) == (textEditingController == null),
            'you should define focusNode and textEditingController simultaneously.'),
        assert(
          !(textEditingController != null && initialValue != null),
          'textEditingController and initialValue cannot be simultaneously defined.',
        ),
        super(key: key);

  /// {@macro flutter.widgets.RawAutocomplete.optionsBuilder}
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  /// {@macro flutter.widgets.RawAutocomplete.fieldViewBuilder}
  final Widget Function(
          BuildContext, TextEditingController, FocusNode, void Function())
      fieldViewBuilder;

  /// The max height of options field view.
  final double? maxHeight;

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@macro flutter.widgets.RawAutocomplete.split}
  ///
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// [controller] is used for storing options easily.
  final ElasticAutocompleteController<T>? controller;

  /// {@macro flutter.widgets.RawAutocomplete.onSelected}
  final void Function(T)? onSelected;

  /// The [TextEditingController] that is used for the text field.
  ///
  /// {@macro flutter.widgets.RawAutocomplete.split}
  ///
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// {@macro flutter.widgets.RawAutocomplete.initialValue}
  ///
  /// Setting the initial value does not notify [textEditingController]'s
  /// listeners, and thus will not cause the options UI to appear.
  ///
  /// This parameter is ignored if [textEditingController] is defined.
  final TextEditingValue? initialValue;

  @override
  State<ElasticAutocomplete> createState() => ElasticAutocompleteState<T>();
}

class ElasticAutocompleteState<T extends String>
    extends State<ElasticAutocomplete<T>> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => RawAutocomplete<T>(
              focusNode: widget.focusNode,
              onSelected: widget.onSelected,
              textEditingController: widget.textEditingController,
              initialValue: widget.initialValue,
              optionsBuilder: widget.optionsBuilder,
              fieldViewBuilder: widget.fieldViewBuilder,
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      width: constraints.biggest.width,
                      constraints: BoxConstraints(
                        maxHeight: widget.maxHeight ?? 200.0,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final T option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Builder(builder: (BuildContext context) {
                              final bool highlight =
                                  AutocompleteHighlightedOption.of(context) ==
                                      index;
                              if (highlight) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((Duration timeStamp) {
                                  Scrollable.ensureVisible(context,
                                      alignment: 0.5);
                                });
                              }
                              return Container(
                                color: highlight
                                    ? Theme.of(context).focusColor
                                    : null,
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                    RawAutocomplete.defaultStringForOption(
                                        option)),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ));
  }
}

/// A controller for an ElasticAutocomplete, which controls the list of options.
class ElasticAutocompleteController<T extends String> {
  /// [id] is used to distinguish different memory units.
  final String id;

  /// With localStorage, the data is persisted until the user manually
  /// clears cache.
  final bool useLocalStorage;

  /// Decide [optionsBuilder] to be case sensitive or not.
  final bool caseSensitive;

  /// Returns true to add [candidate] to the option list
  bool Function(T candidate, String userInput)? contains;

  LocalStorage? _storage;
  final Map<String, Set> _sessionStorage = <String, Set>{};

  /// You can set [contains] in order to decide which options should be chosen.
  /// from the memory unit. Your custom [contains] function will be used
  /// in [optionsBuilder].
  ///
  /// If you set [contains], then [caseSensitive] is neglected.
  ElasticAutocompleteController({
    required this.id,
    this.useLocalStorage = true,
    this.caseSensitive = false,
    this.contains,
  }) {
    if (useLocalStorage) {
      _storage = LocalStorage(id);
    } else {
      _sessionStorage[id] = <T>{};
    }
  }

  /// Load options from the storage unit as a set.
  Set<T> loadSet() {
    if (useLocalStorage) {
      try {
        return Set.from(jsonDecode(_storage!.getItem(id))['info'].cast<T>());
      } catch (e) {
        return <T>{};
      }
    }
    return _sessionStorage[id]?.cast<T>() ?? <T>{};
  }

  /// Load options from the storage unit as a list.
  List<T> loadList() {
    if (useLocalStorage) {
      try {
        return jsonDecode(_storage!.getItem(id))['info'].cast<T>();
      } catch (e) {
        return <T>[];
      }
    }
    return _sessionStorage[id]?.toList().cast<T>() ?? <T>[];
  }

  /// Store [val] to the storage unit.
  Future store(T val) async {
    if (useLocalStorage) {
      var oldList = loadList();
      if (!oldList.any((element) => element == val)) {
        oldList.add(val);
      }

      return await _storage!.setItem(id, jsonEncode({'info': oldList}));
    }
    return _sessionStorage[id]?.add(val);
  }

  /// Clear all options in the storage unit.
  void clear() {
    if (useLocalStorage) {
      _storage!.setItem(id, jsonEncode({}));
      return;
    }
    _sessionStorage[id] = <T>{};
  }

  Iterable<T> optionsBuilder(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') {
      return List<T>.empty();
    }

    return loadList().where((T option) {
      return contains?.call(option, textEditingValue.text) ??
          (caseSensitive
              ? option.contains(textEditingValue.text)
              : option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
    });
  }
}
