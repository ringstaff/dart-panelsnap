/*
 * Dart.panelsnap
 * A port of jQuery panelSnap 0.9.2 (Copyright 2013, Guido Bouman)
 * (https://github.com/guidobouman/jquery-panelsnap)
 * 
 * Copyright 2013, Travis Ringstaff
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Date: Thurs Dec 19 16:08:00 2013 -0500
 */


library panelsnap;

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
      listeners.add(eventContainer.onMouseWheel.listen((e) => new Timer(new Duration(milliseconds: 100), scrollStop)));
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
