import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs  1.2

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0

Rectangle {
    id:     _root
    height: _itemHeight
    width:  _totalSlots * _itemWidth
    color:  qgcPal.textField

    property Fact   fact:               undefined
    property int    characterCount:     8           ///< The minimum number of characters to show for each value
    property int    incrementSlots:     1           ///< The number of visible slots to left/right of center value

    property int    _digitCount:            _model.initialValueAtPrecision.toString().length
    property int    _totalCharacterCount:   Math.max(characterCount, _digitCount + 1 + fact.units.length)
    property real   _margins:               Math.round(ScreenTools.defaultFontPixelHeight * 0.2)
    property real   _itemWidth:             (_totalCharacterCount * ScreenTools.defaultFontPixelWidth) + _margins
    property real   _itemHeight:            ScreenTools.implicitTextFieldHeight * 0.8
    property int    _totalSlots:            (incrementSlots * 2) + 1
    property int    _currentIndex:          _totalSlots / 2
    property int    _prevIncrementSlots:    incrementSlots
    property int    _nextIncrementSlots:    incrementSlots
    property var    _model:                 fact.valueSliderModel()
    property var    _fact:                  fact

    QGCPalette { id: qgcPal; colorGroupEnabled: _root.enabled }

    function firstVisibleIndex() {
        return valueListView.contentX / _itemWidth
    }

    function reset() {
        valueListView.positionViewAtIndex(0, ListView.Beginning)
        _currentIndex = _model.resetInitialValue()
        valueListView.positionViewAtIndex(_currentIndex, ListView.Center)
    }

    Component.onCompleted: {
        valueListView.maximumFlickVelocity = valueListView.maximumFlickVelocity / 2
        reset()
    }

    Connections {
        target:         _fact
        onValueChanged: reset()
    }

    Component {
        id: editDialogComponent

        ParameterEditorDialog {
            fact:       _fact
            setFocus:   ScreenTools.isMobile ? false : true // Works around strange android bug where wrong virtual keyboard is displayed
        }
    }

    QGCListView {
        id:             valueListView
        anchors.fill:   parent
        orientation:    ListView.Horizontal
        snapMode:       ListView.SnapToItem
        clip:           true
        model:          _model

        delegate: QGCLabel {
            width:                  _itemWidth
            height:                 _itemHeight
            verticalAlignment:      Text.AlignVCenter
            horizontalAlignment:    Text.AlignHCenter
            text:                   value === ">>>" || value === "<<<" ? value : value + " " + fact.units
            color:                  qgcPal.text

            MouseArea {
                anchors.fill:   parent
                onClicked: {
                    valueListView.focus = true
                    if (index === 0 || index === valueListView.count - 1) {
                        return
                    }
                    if (_currentIndex === index) {
                        mainWindow.showComponentDialog(editDialogComponent, qsTr("Value Details"), mainWindow.showDialogDefaultWidth, StandardButton.Save | StandardButton.Cancel)
                    } else {
                        _currentIndex = index
                        valueListView.positionViewAtIndex(_currentIndex, ListView.Center)
                        fact.value = value
                    }
                }
            }
        }

        onMovementStarted: valueListView.focus = true

        onMovementEnded: {
            _currentIndex = firstVisibleIndex() + 1
            fact.value = _model.valueAtModelIndex(_currentIndex)
        }
    }

    Rectangle {
        id:         leftOverlay
        width:      _itemWidth * _prevIncrementSlots
        height:     _itemHeight
        color:      qgcPal.textField
        opacity:    0.5
    }

    Rectangle {
        id:             rightOverlay
        width:          _itemWidth * _nextIncrementSlots
        height:         _itemHeight
        anchors.right:  parent.right
        color:          qgcPal.textField
        opacity:        0.5
    }

    Rectangle {
        x:              _itemWidth - _borderWidth
        y:              -_borderWidth
        width:          _itemWidth + (_borderWidth * 2)
        height:         _itemHeight + (_borderWidth * 2)
        border.width:   _borderWidth
        border.color:   qgcPal.brandingBlue
        color:          "transparent"

        readonly property int _borderWidth: 2
    }
}
