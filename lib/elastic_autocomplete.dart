library elastic_autocomplete;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:convert';

/// A widget wraps [RawAutocomplete].
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
    required this.optionsBuilder,
    required this.fieldViewBuilder,
    this.controller,
    this.textEditingController,
    this.focusNode,
    this.onSelected,
    this.initialValue,
    this.optionsViewBuilder,
    this.optionsViewMaxHeight = 200.0,
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

  /// The max height of options view.
  final double optionsViewMaxHeight;

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

  /// {@macro flutter.widgets.RawAutocomplete.optionsViewBuilder}
  final Widget Function(BuildContext, void Function(T), Iterable<T>)?
      optionsViewBuilder;

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
              optionsViewBuilder: widget.optionsViewBuilder ??
                  (BuildContext context, AutocompleteOnSelected<T> onSelected,
                      Iterable<T> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: Container(
                          width: constraints.biggest.width,
                          constraints: BoxConstraints(
                            maxHeight: widget.optionsViewMaxHeight,
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
                                      AutocompleteHighlightedOption.of(
                                              context) ==
                                          index;
                                  if (highlight) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback(
                                            (Duration timeStamp) {
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
  /// You can set [contains] in order to decide which options should be chosen.
  /// from the memory unit. Your custom [contains] function will be used
  /// in [optionsBuilder]. If you set [contains], then [caseSensitive]
  /// is neglected.
  ElasticAutocompleteController({
    required this.id,
    this.useLocalStorage = true,
    this.caseSensitive = false,
    this.latestFirst = true,
    this.initialOptions,
    this.showTopKWhenInputEmpty = 0,
    this.contains,
  }) {
    if (useLocalStorage) {
      _storage = LocalStorage(id);
    } else {
      sessionStorage[id] = <T>[];
    }
    if (initialOptions != null) {
      _storeList(initialOptions!);
    }
  }

  /// [id] is used to distinguish different memory units.
  final String id;

  /// With localStorage, the data is persisted until the user manually
  /// clears cache.
  final bool useLocalStorage;

  /// Decide [optionsBuilder] to be case sensitive or not.
  final bool caseSensitive;

  /// If true, the new value is considered first.
  final bool latestFirst;

  /// Pass the initial options.
  final List<T>? initialOptions;

  /// Show at most how many options even if the users input nothing.
  final int showTopKWhenInputEmpty;

  /// Returns true to add [candidate] to the option list
  ///
  /// If you set [contains], then [caseSensitive]
  /// is neglected.
  bool Function(T candidate, String userInput)? contains;

  LocalStorage? _storage;
  static Map<String, List> sessionStorage = <String, List>{};

  /// Load options from the storage unit.
  List<T> load() {
    if (useLocalStorage) {
      try {
        return jsonDecode(_storage!.getItem(id))['info'].cast<T>();
      } catch (e) {
        return <T>[];
      }
    }
    return sessionStorage[id]?.cast<T>() ?? <T>[];
  }

  /// Store [val] to the storage unit.
  Future store(T val) async {
    var oldList = load();
    List<T> newList = <T>[];

    if (latestFirst) {
      newList.add(val);
    }

    if (caseSensitive) {
      for (var e in oldList) {
        if (e == val) {
          continue;
        }
        newList.add(e);
      }
    } else {
      for (var e in oldList) {
        if (e.toLowerCase() == val.toLowerCase()) {
          continue;
        }
        newList.add(e);
      }
    }

    if (!latestFirst) {
      newList.add(val);
    }

    _storeList(newList);
  }

  Future _storeList(List<T> list) async {
    if (useLocalStorage) {
      return await _storage!.setItem(id, jsonEncode({'info': list}));
    }
    return sessionStorage[id] = list;
  }

  /// Clear all options in the storage unit.
  void clear() async {
    if (useLocalStorage) {
      return await _storage!.setItem(id, jsonEncode({}));
    }
    sessionStorage[id] = <T>[];
  }

  Iterable<T> optionsBuilder(TextEditingValue textEditingValue) {
    List<T> options = load();

    if (textEditingValue.text == '') {
      return options.sublist(0, min(options.length, showTopKWhenInputEmpty));
    }

    return options.where((T option) {
      return contains?.call(option, textEditingValue.text) ??
          (caseSensitive
              ? option.contains(textEditingValue.text)
              : option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
    });
  }

  AutocompleteFieldViewBuilder fieldViewBuilder({
    Key? key,
    InputDecoration? decoration = const InputDecoration(),
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    bool? showCursor,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    MaxLengthEnforcement? maxLengthEnforcement,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    ValueChanged<String>? onChanged,
    GestureTapCallback? onTap,
    VoidCallback? onEditingComplete,
    void Function(String)? onFieldSubmitted,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
  }) {
    return (
      BuildContext context,
      TextEditingController textEditingController,
      FocusNode focusNode,
      void Function() onFieldSubmittedInner,
    ) {
      return TextFormField(
          key: key,
          controller: textEditingController,
          focusNode: focusNode,
          decoration: decoration,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          style: style,
          strutStyle: strutStyle,
          textDirection: textDirection,
          textAlign: textAlign,
          textAlignVertical: textAlignVertical,
          autofocus: autofocus,
          readOnly: readOnly,
          showCursor: showCursor,
          obscuringCharacter: obscuringCharacter,
          obscureText: obscureText,
          autocorrect: autocorrect,
          smartDashesType: smartDashesType,
          smartQuotesType: smartQuotesType,
          enableSuggestions: enableSuggestions,
          maxLengthEnforcement: maxLengthEnforcement,
          maxLines: maxLines,
          minLines: minLines,
          expands: expands,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: (String value) {
            onFieldSubmittedInner();
            onFieldSubmitted?.call(value);
          },
          onSaved: onSaved,
          validator: validator,
          inputFormatters: inputFormatters,
          enabled: enabled,
          cursorWidth: cursorWidth,
          cursorHeight: cursorHeight,
          cursorRadius: cursorRadius,
          cursorColor: cursorColor,
          keyboardAppearance: keyboardAppearance,
          scrollPadding: scrollPadding,
          enableInteractiveSelection: enableInteractiveSelection,
          selectionControls: selectionControls,
          buildCounter: buildCounter,
          scrollPhysics: scrollPhysics,
          autofillHints: autofillHints,
          autovalidateMode: autovalidateMode,
          scrollController: scrollController,
          restorationId: restorationId,
          enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
          mouseCursor: mouseCursor);
    };
  }
}
