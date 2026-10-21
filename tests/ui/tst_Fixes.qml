import QtQuick
import QtTest
import "../panels" as Panels
import "../widgets" as Widgets
import "../components"
import "../services"
Item {
 id: scene
 width: 1000; height: 700
 Rectangle {
  id: card
  x: 50; y: 60; width: 380; height: 400
  Panels.ClipboardPanel { id: editor; anchors.fill: parent; dragTarget: card; active: true }
 }
 Widgets.Updates { id: updates; x:500; y:30; width:implicitWidth; height:28 }
 Widgets.Network { id: network; x:500; y:80; ctx:({vertical:false,options:{detail:"compact"}}); width:implicitWidth; height:28 }
 TestCase {
  name: "ShellFixes"; when: windowShown
  function init() { card.x=50; card.y=60 }
  function test_clipboardHeaderDrags() {
   const start=editor.children[0].mapToItem(scene,80,16)
   mousePress(scene,start.x,start.y)
   mouseMove(scene,start.x+20,start.y+20,30)
   mouseMove(scene,start.x+130,start.y+70,30)
   mouseRelease(scene,start.x+130,start.y+70)
   verify(card.x > 100, "Header must move the card horizontally: " + card.x)
   verify(card.y > 90, "Header must move the card vertically: " + card.y)
  }
  function test_clipboardDragStaysOnScreen() {
   const start=editor.children[0].mapToItem(scene,80,16)
   mousePress(scene,start.x,start.y)
   mouseMove(scene,start.x+20,start.y+20,30)
   mouseMove(scene,990,690,30)
   mouseRelease(scene,990,690)
   verify(card.x <= scene.width-card.width-8)
   verify(card.y <= scene.height-card.height-8)
   verify(card.x >= 8 && card.y >= 8)
  }
  function test_updateCountSizesFromText() {
   Updates.count=1; wait(20); const one=updates.implicitWidth
   Updates.count=18; wait(20); const two=updates.implicitWidth
   Updates.count=379; wait(20); const three=updates.implicitWidth
   verify(two>one && three>two, "Count must grow with rendered digits")
   compare(updates.minimumContentWidth,updates.implicitWidth-14)
  }
  function test_networkIconIsCentered() {
   wait(20)
   const row=network.children.find(c => c.children && c.children.some(i => i.name === "wifi"))
   verify(row !== undefined)
   const icon=row.children.find(c => c.name === "wifi")
   const centre=icon.mapToItem(network,icon.width/2,icon.height/2)
   fuzzyCompare(centre.x,network.width/2,0.1)
  }
 }
}