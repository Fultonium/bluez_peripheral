import 'package:dbus/dbus.dart';

import 'enums.dart';

enum AdvertisingPacketType {
  broadcast,
  peripheral,
}

class Advertisement extends DBusObject {
  String? localName;
  List<String>? serviceUuids;
  int? appearance;
  int? timeout;
  bool? discoverable;
  AdvertisingPacketType? type;
  List<String>? solicitUuids;
  int? duration;

  Advertisement({
    required String path,
    required this.localName,
    this.serviceUuids,
    this.appearance,
    this.timeout = 0,
    this.discoverable = true,
    this.type = AdvertisingPacketType.peripheral,
    this.solicitUuids,
    this.duration = 2,
  }) : super(DBusObjectPath(path));

  /// Called when all properties are requested on this object. On success, return [DBusGetAllPropertiesResponse].
  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
        "org.bluez.LEAdvertisement1": {
          if (localName != null) "LocalName": DBusString(localName!),
          if (serviceUuids != null)
            "ServiceUUIDs": DBusArray.string(serviceUuids!),
          if (appearance != null) "Appearance": DBusUint16(appearance!),
          if (timeout != null) "Timeout": DBusUint16(timeout!),
          if (discoverable != null) "Discoverable": DBusBoolean(discoverable!),
          if (type != null) "Type": DBusString(describeEnum(type!)),
          if (solicitUuids != null)
            "SolicitUUIDS": DBusArray(
                DBusSignature.string, solicitUuids!.map((e) => DBusString(e)))
        }
      };

  /// Called when a method call is received on this object.
  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == "org.bluez.LEAdvertisement1" &&
        methodCall.name == "Release") {
      return DBusMethodSuccessResponse();
    }
    return DBusMethodErrorResponse.unknownInterface();
  }

  /// Called when a property is requested on this object. On success, return [DBusGetPropertyResponse].
  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    var interfaceProperties = interfacesAndProperties[interface];
    if (interfaceProperties == null) {
      return DBusMethodErrorResponse.unknownInterface();
    }

    var property = interfaceProperties[name];
    if (property == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }

    return DBusGetPropertyResponse(property);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    return DBusGetAllPropertiesResponse(interfacesAndProperties[interface]!);
  }
}

class AdvertisingManager extends DBusRemoteObject {
  static const _interface = "org.bluez.LEAdvertisingManager1";

  AdvertisingManager(
    super.client,
  ) : super(name: "org.bluez", path: DBusObjectPath("/org/bluez/hci0"));

  Future<void> registerAdvertisement(Advertisement advertisement) async {
    await client.registerObject(advertisement);
    try {
      await super.callMethod(_interface, "RegisterAdvertisement", [
        advertisement.path,
        DBusDict(DBusSignature("s"), DBusSignature("v"))
      ]);
    } catch (e) {
      print(e);
    } finally {
      await client.unregisterObject(advertisement);
    }
  }
}
