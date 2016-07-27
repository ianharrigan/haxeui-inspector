package haxe.ui.tools.inspector;

import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.remoting.ComponentInfo;
import haxe.ui.remoting.Util;
import haxe.ui.remoting.server.Client;
import haxe.ui.remoting.server.Server;

class Main {
    public static function main() {
        var server:Server = new Server();

        Toolkit.init();

        var main:Component = ComponentMacros.buildComponent("assets/ui/main.xml");
        Screen.instance.addComponent(main);

        var result:Label = main.findComponent("result", null, true);
        var scrollview:ScrollView = main.findComponent("clientList", null, true);
        server.onConnected = function(client:Client) {
            var button:Button = new Button();
            button.text = client.uuid.split("-").pop();
            button.id = client.uuid;
            button.userData = client;
            button.percentWidth = 100;
            button.onClick = function(e) {
                client.makeCall("components.list", function(components:Array<ComponentInfo>) {
                   trace(Util.buildComponentInfo(components[0]));
                   result.text = Util.buildComponentInfo(components[0]);
                });
            };

            scrollview.contents.addComponent(button);
        };
    }
}
