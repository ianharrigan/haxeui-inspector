package haxe.ui.tools.inspector;

import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxe.ui.core.MouseEvent;
import haxe.ui.core.Screen;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.parsers.modules.ModuleParser;
import haxe.ui.remoting.ComponentInfo;
import haxe.ui.remoting.Util;
import haxe.ui.remoting.server.Client;
import haxe.ui.remoting.server.Server;
import openfl.Lib;
import openfl.events.Event;

class Main {
    private static var _currentComponent:ComponentInfo;
    private static var _main:Component;
    private static var server:Server;
    private static var _currentClient:Client;
    private static var _currentUuid:String;

    public static function main() {
        server = new Server();
        server.start();

        Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        Toolkit.init();

        _main = ComponentMacros.buildComponent("assets/ui/main.xml");
        Screen.instance.addComponent(_main);

        //var result:Label = _main.findComponent("result", null, true);
        var scrollview:ScrollView = _main.findComponent("clientList", null, true);
        //var resultList:ScrollView = _main.findComponent("resultList", null, true);
        server.onConnected = function(client:Client) {
            var button:Button = new Button();
            button.text = client.uuid.split("-").pop();
            button.id = client.uuid;
            button.userData = client;
            button.percentWidth = 100;
            button.onClick = function(e) {
                client.makeCall("components.list", function(components:Array<ComponentInfo>) {
                   //trace(Util.buildComponentInfo(components[0]));
                   //result.text = Util.buildComponentInfo(components[0]);
                   _currentClient = client;
                   _currentComponent = components[0];
                });
            };

            scrollview.contents.addComponent(button);
        };

        server.onDisconnected = function(client:Client) {
            var button:Button = scrollview.findComponent(client.uuid, Button, true);
            scrollview.contents.removeComponent(button);

            if (_currentClient.uuid == client.uuid) {
                var resultList:ScrollView = _main.findComponent("resultList", null, true);
                resultList.contents.removeAllComponents();
            }
        };
    }

    private static function onEnterFrame(event:Event) {
        if (_currentComponent != null) { // TODO: need think of a much better way to handle this, the problem is threading!
            var temp = _currentComponent;
            _currentComponent = null;
            var resultList:ScrollView = _main.findComponent("resultList", null, true);
            populateResult(resultList, temp);
        }
    }

    private static var ICON_MAP:Map<String, String> = [
        "vbox" => "ui-split-panel-vertical.png",
        "label" => "ui-label.png",
        "image" => "image-sunset.png",
        "hbox" => "ui-split-panel.png",
        "button" => "ui-button.png"
    ];

    private static function populateResult(resultList:ScrollView, info:ComponentInfo, indent:Int = 0) {
        var box:Box = ComponentMacros.buildComponent("assets/ui/tree-item.xml");
        box.paddingLeft = indent * 20;

        var client:Client = _currentClient;

        var details:Box = box.findComponent("details", Box, true);
        box.registerEvent(MouseEvent.MOUSE_OVER, function(e) {
            box.backgroundColor = 0xEEEEEE;
            client.makeCall("component.highlight", ["id" => info.id, "highlight" => "true"]);
        });
        box.registerEvent(MouseEvent.MOUSE_OUT, function(e) {
            box.backgroundColor = 0xFFFFFF;
            client.makeCall("component.highlight", ["id" => info.id, "highlight" => "false"]);
        });

        var props:Component = box.findComponent("props", Component, true);
        props.hide();
        if (info.text != null)                 addProp(props, 'text', '${info.text}');
        if (info.left != null)                 addProp(props, 'left', '${info.left}');
        if (info.top != null)                  addProp(props, 'top', '${info.top}');
        if (info.width != null)                addProp(props, 'width', '${info.width}');
        if (info.height != null)               addProp(props, 'height', '${info.height}');
        if (info.percentWidth != null)         addProp(props, 'percentWidth', '${info.percentWidth}');
        if (info.percentHeight != null)        addProp(props, 'percentHeight', '${info.percentHeight}');

        var label = box.findComponent("label", Label, true);
        var labelString:String = info.className.split(".").pop();

        var icon:Image = box.findComponent("icon", Image, true);
        if (ICON_MAP.exists(labelString.toLowerCase())) {
            icon.resource = "icons/" + ICON_MAP.get(labelString.toLowerCase());
        }

        if (info.id != null && StringTools.startsWith(info.id, "__") == false) {
            labelString = "#" + info.id + " [" + labelString + "]";
        }
        label.text = labelString;

        resultList.addComponent(box);

        if (info.children != null) {
            for (child in info.children) {
                populateResult(resultList, child, indent + 1);
            }
        }
    }

    private static function addProp(props:Component, name:String, value:String) {
        var hbox:HBox = new HBox();
        hbox.percentWidth = 100;

        var nameLabel:Label = new Label();
        nameLabel.text = " - " + name + ":";
        nameLabel.width = 75;
        hbox.addComponent(nameLabel);

        var valueLabel:Label = new Label();
        valueLabel.text = value;
        //valueLabel.percentWidth = 100;
        valueLabel.width = 100;
        hbox.addComponent(valueLabel);

        props.addComponent(hbox);
    }
}
