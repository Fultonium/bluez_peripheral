import 'package:bluez_peripheral/bluez_peripheral.dart';
import 'package:dbus/dbus.dart';

void main() async {
  var dbus = DBusClient.system(introspectable: true);

  var advertisement = Advertisement(
    path: "/org/bluez/Advert",
    localName: "DartTest",
    appearance: 0,
    discoverable: true,
    timeout: 0,
  );

  print(CharacteristicOptionFlag.writeWithoutResponse.value());

  var gattService1 =
      LocalGattService(uuid: "78befa98-8f43-4298-a0a4-badea0e9be46");
  var gattCharacteristic1 = LocalGattCharacteristic(
      uuid: "78befa99-8f43-4298-a0a4-badea0e9be46",
      serviceUuid: "78befa98-8f43-4298-a0a4-badea0e9be46",
      flags: [
        CharacteristicOptionFlag.read,
        CharacteristicOptionFlag.writeWithoutResponse,
        CharacteristicOptionFlag.write,
        CharacteristicOptionFlag.notify,
      ]);
  gattService1.addCharacteristic(gattCharacteristic1);

  var gattManager = GattManager(dbus);

  await gattManager.registerApplication([gattService1]);
  await gattCharacteristic1.setValue([0x12, 0x34]);

  var advertisingManager = AdvertisingManager(dbus);
  await advertisingManager.registerAdvertisement(advertisement);

  while (true) {
    await Future.delayed(Duration(seconds: 10));
    var value = gattCharacteristic1.getValue();
    value[1] = value[1] + 1;
    gattCharacteristic1.setValue(value);
  }
}
