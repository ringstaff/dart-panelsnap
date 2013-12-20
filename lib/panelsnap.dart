/*
 * Dart panelSnap
 * Copyright 2013, Travis Ringstaff
 * 
 * A port of jQuery panelSnap 0.9.2
 * (https://github.com/guidobouman/jquery-panelsnap)
 * (Copyright 2013, Guido Bouman)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Date: Thurs Dec 19 16:08:00 2013 -0500
 */


library panel_snap;

import 'dart:html';
import 'dart:math' as Math;
import 'package:animation/animation.dart';
import 'dart:async';

class PanelSnap {
  bool isMouseDown = false, 
       isSnapping = false;
  
  int scrollInterval = 0, 
      scrollOffset = 0,
      directionThreshold = 50, 
      slideSpeed = 400;
  
  Element container, 
          eventContainer, 
          snapContainer;
  
  var _menu = false;
  
  String menuSelector = 'a', 
         panelSelector = 'section', 
         namespace = '.panelSnap';

  var onSnapStart, onSnapFinish, onActivate;
  
  StreamSubscription tempListener;
  
  List listeners = [], 
       panels = [];
  
  ElementAnimation snapContainerAnimation, 
                   containerAnimation;
  
  PanelSnap(this.container, [var menu]) {
    if(container == null) {
      throw new Exception('Container is null.');
      return;
    }
    
    eventContainer = snapContainer = container;
    
    panels = new List.from(container.children);

    if(container == document.body) {
      // remove ScriptElements from panels list
      panels.retainWhere((Element e) => e is! ScriptElement);
    }
    
    scrollInterval = container.clientHeight;
    
    bind();
    
    if(menu != null)
      this.menu = menu;
      
    if(_menu != false && querySelectorAll('.active ${(_menu as Element).id}').length > 0) {
      querySelector('.active ${(_menu as Element).id}').click();
    } else {
      var target = getPanel(':first-child');
      activatePanel(target);
    }
  }
  
  set menu(menu) {
    if(menu == null) {
      throw new Exception('Menu element is null.');
      return;
    }
    _menu = menu;
    if(_menu is Element)
      _menu.children.forEach((Element e) => e.onClick.listen(captureMenuClick));
  }
  
  get menu {
    return _menu;
  }

  bind() {
    if(eventContainer == document.body)
      listeners.add(eventContainer.onMouseWheel.listen((e) => new Timer(new Duration(milliseconds: 50), scrollStop)));
    else
      listeners.add(eventContainer.onScroll.listen(scrollStop));
    
    listeners.add(eventContainer.onMouseDown.listen(mouseDown));
    listeners.add(eventContainer.onMouseUp.listen(mouseUp));
    listeners.add(window.onResize.listen(resize));
  }

  destroy() {
    for(StreamSubscription listener in listeners) 
      listener.cancel();
  }

  scrollStop([Event e]) {
    if(tempListener != null) {
      tempListener.cancel();
      tempListener = null;
    }
    
    if(isMouseDown) {
      tempListener = eventContainer.onMouseUp.listen(scrollStop);
      return;
    }

    if(isSnapping) {
      return;
    }

    var offset = eventContainer.scrollTop;
    
    var scrollDifference = offset - scrollOffset;
    var maxOffset = container.scrollHeight - scrollInterval;
    var panelCount = container.children.length;

    var childNumber;
    if(scrollDifference < -directionThreshold && scrollDifference > -scrollInterval) {
      childNumber = (offset / scrollInterval).floor();
    } else if(scrollDifference > directionThreshold && scrollDifference < scrollInterval) {
      childNumber = (offset / scrollInterval).ceil();
    } else {
      childNumber = (offset / scrollInterval).round();
    }

    childNumber = Math.max(0, Math.min(childNumber, panelCount));
    if(childNumber >= panels.length)
      return;
    
    var target = panels[childNumber];
    
    if((scrollDifference == 0) || (scrollDifference < 100 && (offset < 0 || offset > maxOffset))) {
      activatePanel(target);
    } else {
      snapToPanel(target);
    }
  }

  mouseDown(e) {
    isMouseDown = true;
  }

  mouseUp(e) {
    isMouseDown = false;
  }

  resize(e) {
    scrollInterval = container.clientHeight;
    snapToPanel(getPanel('.active'));
  }

  captureMenuClick(MouseEvent e) {
    e.preventDefault();
    var panel = (e.currentTarget as Element).dataset['panel'];
    snapToPanel(getPanel('[data-panel=${panel}]'));
    return false;
  }

  snapToPanel(Element target) {
    isSnapping = true;

    if(onSnapStart is Function)
      onSnapStart(target);
    
    container.dispatchEvent(new CustomEvent('panelsnap:start', detail: target));
    var scrollTarget = target.offset.top;

    if(snapContainerAnimation != null) 
      snapContainerAnimation.stop();
      
    snapContainerAnimation = new ElementAnimation(snapContainer)
        ..duration = slideSpeed
        ..properties = { 'scrollTop': scrollTarget }
        ..onComplete.listen((e) {
          scrollOffset = scrollTarget;
          isSnapping = false;
          
          // Call callback
          if(onSnapFinish is Function)
            onSnapFinish(target);
          
          container.dispatchEvent(new CustomEvent('panelsnap:finish', detail: target));
        })
        ..run();
          
    activatePanel(target);
  }

  activatePanel(Element target) {
    var temp = container.querySelector(panelSelector + '.active');
    if(temp != null)
      temp.classes.remove('active');
    
    target.classes.add('active');

    if(_menu != false) {
      _menu.querySelector(menuSelector + '.active').classes.remove('active');

      var itemSelector = menuSelector + '[data-panel=${target.dataset['panel']}]';
      var activeItem = _menu.querySelector(itemSelector);
      activeItem.classes.add('active');
    }
    
    if(onActivate is Function)
      onActivate(target);
    container.dispatchEvent(new CustomEvent('panelsnap:activate', detail: target));
  }

  Element getPanel([selector]) {
    if(selector == null) {
      selector = '';
    }

    return container.querySelector(panelSelector + selector);
  }

  void snapTo(target, wrap) {
    if(wrap is! bool) {
      wrap = true;
    }

    var _target;

    switch(target) {
      case 'prev':
        _target = getPanel('.active').previousElementSibling;
        if(_target.length < 1 && wrap) 
          _target = getPanel(':last');
        break;
      case 'next':
        _target = getPanel('.active').nextElementSibling;
        if(_target.length < 1 && wrap)
          _target = getPanel(':first');
        break;
      case 'first':
        _target = getPanel(':first');
        break;
      case 'last':
        _target = getPanel(':last');
        break;
    }

    if(_target.length > 0) {
      snapToPanel(_target);
    }
  }
}
