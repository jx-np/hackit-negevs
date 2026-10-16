// NOTE (vendored patch): Flutter 3.44+ marked [IconData] as a `final` class, so
// the upstream subclasses `class IconDataX extends IconData` no longer compile.
//
// Those subclasses existed only to preset `fontFamily`/`fontPackage` on an
// otherwise-plain [IconData]. The vendored patch removes them entirely and, in
// `font_awesome_flutter.dart`, rewrites every `IconDataSolid(0x..)` /
// `IconDataBrands(0x..)` / `IconDataRegular(0x..)` call into a direct const
// `IconData(0x.., fontFamily: 'FontAwesome<Style>', fontPackage: 'font_awesome_flutter')`.
// The icon constants stay typed as `IconData` and `FaIcon` keeps reading only
// `codePoint`/`fontFamily`/`fontPackage`, so behaviour is identical.
//
// No code in this package (or in image_editor_plus, the sole consumer) refers to
// the old subclass type names, so this file intentionally declares nothing.
