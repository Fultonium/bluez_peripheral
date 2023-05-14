import 'package:dbus/dbus.dart';

import 'enums.dart';

const _gattRoot = "/za/co/mathewfulton/GATT";

class LocalGattService extends DBusObject {
  static const String _interface = "org.bluez.GattService1";

  String uuid;
  bool? primary;

  List<LocalGattCharacteristic> characteristics = [];

  LocalGattService({required this.uuid, this.primary = true})
      : super(DBusObjectPath("$_gattRoot/${uuid.replaceAll(r'-', "_")}"));

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
        _interface: {
          "UUID": DBusString(uuid),
          "Primary": DBusBoolean(primary!),
        }
      };

  /// Called when all properties are requested on this object. On success, return [DBusGetAllPropertiesResponse].
  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    return DBusGetAllPropertiesResponse(interfacesAndProperties[interface]!);
  }

  void addCharacteristic(LocalGattCharacteristic characteristic) {
    characteristics.add(characteristic);
  }
}

enum CharacteristicOptionFlag {
  broadcast,
  read,
  writeWithoutResponse,
  write,
  notify,
  indicate,
  authenticatedSignedWrites,
  extendedProperties,
  reliableWrite,
  writableAuxiliaries,
  encryptRead,
  encryptWrite,
  encryptNotify,
  encryptIndicate,
  encryptAuthenticatedRead,
  encryptAuthenticatedWrite,
  encryptAuthenticatedNotify,
  encryptAuthenticatedIndicate,
  secureRead,
  secureWrite,
  secureNotify,
  secureIndicate,
  authorize,
}

extension CharacteristicOptionFlagExtension on CharacteristicOptionFlag {
  String value() {
    return describeEnum(this).replaceAllMapped(RegExp("([A-Z])"), (match) {
      return "-${match.group(0)!.toLowerCase()}";
    });
  }
}

class LocalGattCharacteristic extends DBusObject {
  static const String _interface = "org.bluez.GattCharacteristic1";

  List<int> _value = <int>[];

  String uuid;
  String serviceUuid;
  List<CharacteristicOptionFlag> flags;
  int mtu;

  LocalGattService? service;

  LocalGattCharacteristic({
    required this.uuid,
    required this.serviceUuid,
    this.flags = const [CharacteristicOptionFlag.read],
    this.mtu = 2,
  }) : super(DBusObjectPath(
            "$_gattRoot/${serviceUuid.replaceAll(r'-', "_")}/${uuid.replaceAll(r'-', "_")}"));

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
        _interface: {
          "UUID": DBusString(uuid),
          "Service":
              DBusObjectPath("$_gattRoot/${serviceUuid.replaceAll(r'-', "_")}"),
          "Flags": DBusArray.string(flags.map((e) => e.value())),
          "MTU": DBusUint16(mtu),
        }
      };

  /// Called when all properties are requested on this object. On success, return [DBusGetAllPropertiesResponse].
  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    return DBusGetAllPropertiesResponse(interfacesAndProperties[interface]!);
  }

  /// Called when a method call is received on this object.
  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    print("Method call!");
    if (methodCall.interface != _interface) {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case "ReadValue":
        return await _readValue(methodCall.values.first as DBusDict);
      case "WriteValue":
        return await _writeValue(methodCall.values[0] as DBusArray,
            methodCall.values[1] as DBusDict);
    }

    return DBusMethodErrorResponse.notSupported();
  }

  Future<DBusMethodResponse> _readValue(DBusDict flags) async {
    print("Read characteristic $uuid");
    return DBusMethodSuccessResponse([DBusArray.byte(_value)]);
  }

  Future<DBusMethodResponse> _writeValue(
      DBusArray value, DBusDict flags) async {
    print("Wrote characteristic $uuid $flags");
    _value = value.asByteArray().toList();
    print(flags);
    return DBusMethodSuccessResponse();
  }

  Future<void> setValue(List<int> value) async {
    _value = value;
    emitPropertiesChanged(_interface,
        changedProperties: {"Value": DBusArray.byte(_value)});
  }

  List<int> getValue() {
    return List<int>.from(_value);
  }
}

class GattManager extends DBusRemoteObject {
  static const String _interface = "org.bluez.GattManager1";

  GattManager(
    super.client,
  ) : super(name: "org.bluez", path: DBusObjectPath("/org/bluez/hci0"));

  Future<void> registerApplication(List<LocalGattService> services) async {
    for (var s in services) {
      await client.registerObject(s);
      for (var c in s.characteristics) {
        await client.registerObject(c);
      }
    }

    await client.registerObject(
        DBusObject(DBusObjectPath(_gattRoot), isObjectManager: true));
    await callMethod(_interface, "RegisterApplication", [
      DBusObjectPath(_gattRoot),
      DBusDict(DBusSignature("s"), DBusSignature("v"))
    ]);
  }
}
