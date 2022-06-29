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
  final Widget Function(
          BuildContext, TextEditingController, FocusNode, void Function())
      fieldViewBuilder;
  final double? maxHeight;
  final FocusNode? focusNode;
  final ElasticAutocompleteController<T>? controller;

  /// {@macro flutter.widgets.RawAutocomplete.onSelected}
  final void Function(T)? onSelected;
  final TextEditingController? textEditingController;
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

/// A controller for an ElasticAutocomplete
class ElasticAutocompleteController<T extends String> {
  final String id;
  LocalStorage? storage;
  final bool useLocalstorage;
  Map<String, Set> sessionStorage = <String, Set>{};

  /// [id] is used to distinguish different memory unit.
  ///
  /// If you do not want to store value in localstorage, set [useLocalstorage]
  /// to be `false`.
  /// With localStorage , the data is persisted until the user manually clears
  /// the browser cache or app cache.
  ElasticAutocompleteController(
      {required this.id, this.useLocalstorage = true}) {
    if (useLocalstorage) {
      storage = LocalStorage(id);
    } else {
      sessionStorage[id] = <T>{};
    }
  }

  /// load options from the bucket
  Set<T> loadSet() {
    if (useLocalstorage) {
      try {
        return Set.from(jsonDecode(storage!.getItem(id))['info'].cast<T>());
      } catch (e) {
        return <T>{};
      }
    }
    return sessionStorage[id]?.cast<T>() ?? <T>{};
  }

  List<T> loadList() {
    if (useLocalstorage) {
      try {
        return jsonDecode(storage!.getItem(id))['info'].cast<T>();
      } catch (e) {
        return <T>[];
      }
    }
    return sessionStorage[id]?.toList().cast<T>() ?? <T>[];
  }

  /// store [val] to the bucket
  Future store(T val) async {
    if (useLocalstorage) {
      var oldList = loadList();
      if (!oldList.any((element) => element == val)) {
        oldList.add(val);
      }

      return await storage!.setItem(id, jsonEncode({'info': oldList}));
    }
    return sessionStorage[id]?.add(val);
  }

  void clean() {
    if (useLocalstorage) {
      storage!.setItem(id, jsonEncode({}));
      return;
    }
    sessionStorage[id] = <T>{};
  }

  Iterable<T> optionsBuilder(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') {
      return List<T>.empty();
    }
    return loadList().where((String option) {
      return option.contains(textEditingValue.text);
    });
  }
}

