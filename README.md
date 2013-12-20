# dart.panelsnap
A Google Dart plugin that provides snapping functionality to a set of panels within your interface.

Dart.panelsnap is a port of jQuery.panelSnap by Guido Bouman (http://github.com/guidobouman/jquery-panelsnap).

# Demo
Check out the homepage at http://ringstaff.github.io/dart-panelsnap or the demos folder for a working demo that explains most of the features present in the plugin.

# Usage
## The Basics
The most basic setup will bind to body and snap all sections.

```html
<html>
  <body>
    <section>
      ...
    </section>
    <section>
      ...
    </section>
    <section>
      ...
    </section>
	<script type="application/dart">
	
		import 'dart:html';
		import 'package:panelsnap/panelsnap.dart';
      
		void main() {
			new PanelSnap(document.body);
		}
		
	</script>
	<script src="packages/browser/dart.js"></script>
  </body>
</html>
```

## Options
The following is a list of available options. The values are their defaults within the plugin.
```javascript
new PanelSnap(querySelector('.panel_container'))
    ..menu = false
    ..menuSelector = 'a'
    ..panelSelector = 'section'
    ..namespace = '.panelSnap'
    ..onSnapStart = () {}
    ..onSnapFinish = () {}
    ..onActivate = () {}
    ..directionThreshold = 50
    ..slideSpeed = 400;
```

`menu`:
DOM object referencing a menu that contains menu items.

`menuSelector`:
A string containing the css selector to menu items (scoped within the menu).

`panelSelector`:
A string containg the css selector to panels (scoped within the container).

`namespace`:
A string containing the event namespace that's being used.

`onSnapStart`:
A callback function that is being fired before a panel is being snapped.

`onSnapFinish`:
A callback function that is being fired after a panel was snapped.

`onActivate`:
A callback function that is being fired after a panel was activated. (This callback will ALWAYS fire, where onSnapStart & onStapFinish only fire before and after the plugin is actually snapping (animating) towards a panel.)

`directionThreshold`:
An integer specifying the amount of pixels required to scroll before panelsnap detects a direction and snaps to the next panel.

`slideSpeed`:
The amount of milliseconds in which panelsnap snaps to the desired panel.

## Attaching a menu

```html
<html>
  <body>
    <header>
      <div class="menu">
        <a href="/first" data-panel="first">First</a>
        <a href="/second" data-panel="second">Second</a>
        <a href="/third" data-panel="third">Third</a>
      </div>
    </header>
    <div class="panels">
      <section data-panel="first">
        ...
      </section>
      <section data-panel="second">
        ...
      </section>
      <section data-panel="third">
        ...
      </section>
    </div>
	<script type="application/dart">
        import 'dart:html';
        import 'package:panelsnap/panelsnap.dart';
		
		main() {
			new PanelSnap(querySelector('.menu_demo .panels'))
					..menu = querySelector('.menu_demo .menu');
		}
    </script>
	<script src="packages/browser/dart.js"></script>
  </body>
```

Note the `data-panel` attributes on the links and the panels. This way panelsnap knows which link matches to which panel.

# Events
panelsnap emits the following events on the container object in the `panelsnap` namespace:

`panelsnap:start`:
Fired before a panel is being snapped.

`panelsnap:finish`:
Fired after a panel was snapped.

`panelsnap:activate`:
Fired after a panel was activated. (This callback will ALWAYS fire when switching to a panel, where onSnapStart & onStapFinish only fire before and after the plugin is actually snapping (animating) towards a panel.)