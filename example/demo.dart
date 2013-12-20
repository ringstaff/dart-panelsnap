import 'dart:html';
import 'panel_snap.dart';




main() {
  // Basic demo
  new PanelSnap(document.body);
  
  // Menu demo
  new PanelSnap(querySelector('.menu_demo .panels'))
      ..menu = querySelector('.menu_demo .menu');

  // Callback demo
  new PanelSnap(querySelector('.callback_demo .panels'))
      ..onSnapStart = (target) { log('callback', 'onSnapStart', target); }
      ..onSnapFinish = (target) { log('callback', 'onSnapFinish', target); };

  // Event demo      
  Element eventDemoPanels = querySelector('.event_demo .panels')
      ..on['panelsnap:start'].listen((e) => log('event', e.type, e.detail))
      ..on['panelsnap:finish'].listen((e) => log('event', e.type, e.detail));
  
  new PanelSnap(eventDemoPanels);
  
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
}

// Shared log function
log(type, action, Element target) {
  var text = new Element.html('<p>${action}:<br>${target.querySelector('h1').text}</p>');
  querySelector('.${type}_demo .log h2').insertAdjacentElement('afterEnd', text);
}