## 0.2.0

+ Update dependent package `localstorage`
+ Remove parameter `toolbarOptions` in fieldViewBuilder

## 0.1.0

### Rename params

* `maxHeight` -> `optionsViewMaxHeight`

### New feature

* `ElasticAutocomplete`
  * You can customize `optionsViewBuilder`
* `ElasticAutocompleteController`
  * `latestFirst` sorts options by latest input.
  * `showTopKWhenInputEmpty` shows at most K options even if there is no input.
  * `initialOptions` stores all initial options to the memory unit.
  * `fieldViewBuilder` generates a default field view builder.

### Bug fixes

+ When setting `caseSensitive = false` i.e., case-insensitive mode. 
  + If user input `azalea` and then input `AZALEA` later, shows `AZALEA` instead of `azalea`.
+ Share the same storage if `id` is same when not using local storage mode.

## 0.0.1

* Initial development release.