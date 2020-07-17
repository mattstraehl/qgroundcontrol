/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "FactValueSliderListModel.h"

#include <QDebug>
#include <QQmlEngine>
#include <QtMath>

#include <math.h>

const int FactValueSliderListModel::_valueRole =        Qt::UserRole;

FactValueSliderListModel::FactValueSliderListModel(Fact& fact, QObject* parent)
    : QAbstractListModel        (parent)
    , _fact                     (fact)
    , _cValues                  (0)
    , _firstValueIndexInWindow  (0)
    , _initialValueIndex        (0)
    , _cPrevValues              (0)
    , _cNextValues              (0)
    , _initialValue             (0)
    , _initialValueAtPrecision  (0)
    , _increment                (1)
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}

FactValueSliderListModel::~FactValueSliderListModel()
{
}

int FactValueSliderListModel::resetInitialValue(void)
{
    if (_cValues > 0) {
        // Remove any old rows
        beginRemoveRows(QModelIndex(), 0, _cValues - 1);
        _cValues = 0;
        endRemoveRows();
    }

    _initialValue = _fact.cookedValue().toDouble();
    _initialValueAtPrecision = _valueAtPrecision(_initialValue, _fact.decimalPlaces());
    if (_fact.metaData()) {
        // Use the cooked increment value and round it to the nearest integer
        _increment = qRound(_fact.metaData()->rawTranslator()(qMax(1.0, _fact.rawIncrement())).toDouble());
        // Make sure the increment value is at least 1.0
        _increment = qMax(_increment, 1.0);
    }
    _cPrevValues = qMin((_initialValue - _fact.cookedMin().toDouble())  / _increment, 100.0);
    _cNextValues = qMin((_fact.cookedMax().toDouble() - _initialValue)  / _increment, 100.0);
    _initialValueIndex = _cPrevValues + 1; // Plus 1 to account for the empty slot at the beginning

    int totalValueCount = _cPrevValues + 1 + _cNextValues;
    totalValueCount += 2; // Add 2 in order to account for the empty slots at the beginning and end
    beginInsertRows(QModelIndex(), 0, totalValueCount - 1);
    _cValues = totalValueCount;
    endInsertRows();

    emit initialValueAtPrecisionChanged();

    return _initialValueIndex;
}

int FactValueSliderListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);

    return _cValues;
}

QVariant FactValueSliderListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    int valueIndex = index.row();
    if (role == _valueRole) {
        if (valueIndex == 0) {
            return QVariant(">>>");
        }

        if (valueIndex == _cValues - 1) {
            return QVariant("<<<");
        }

        double value;
        int cIncrementCount = valueIndex - _initialValueIndex;
        if (cIncrementCount == 0) {
            value = _initialValue;
        } else {
            value = _initialValue + (cIncrementCount * _increment);
        }

        int decimalPlaces = qMin(1, _fact.decimalPlaces());
        return QVariant(_valueAtPrecision(value, decimalPlaces));
    }

    return QVariant();
}

QHash<int, QByteArray> FactValueSliderListModel::roleNames(void) const
{
    QHash<int, QByteArray> hash;
    hash[_valueRole] = "value";
    return hash;
}

double FactValueSliderListModel::valueAtModelIndex(int index)
{
    return data(createIndex(index, 0), _valueRole).toDouble();
}

double FactValueSliderListModel::_valueAtPrecision(double value, int decimalPlaces) const
{
    double precision = qPow(10, decimalPlaces);
    return qRound(value * precision) / precision;
}
