import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0 &&
        service.uuid.toString().toUpperCase().substring(4, 8) != "180A") {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle:
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;

  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  const CharacteristicTile(
      {Key key,
      this.characteristic,
      this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool flag = false;

    int id = 0x04;
    int cmd;

    int temp = 25;
    int hum = 50;

    int crc(a, b, c) {
      return (a + b + c) % 0x100;
    }

    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        characteristic.setNotifyValue(true);

        final value = snapshot.data;

        final myController = TextEditingController(text: '0x04');
        final tempController = TextEditingController(text: '25');
        final humController = TextEditingController(text: '50');
        final hhController = TextEditingController(text: '12');
        final mmController = TextEditingController(text: '00');

        characteristic.value.listen((value) {
          if (flag == true && value.first == 2 && value.last == 3) {
            if (cmd == 0x49) {
              id = value[2];
              Alert(
                      context: context,
                      title: "ID가 정상적으로 설정되었습니다.",
                      desc: value.toString())
                  .show();
            }

            if (value[1] == id) {
              if (cmd == 0x53) {
                Alert(
                  context: context,
                  title: "온도, 습도가 정상적으로 설정되었습니다.",
                  desc:
                      "온도: ${value[2].toString()}, 습도: ${value[3].toString()}",
                ).show();
              }
              if (cmd == 0x44) {
                Alert(
                        context: context,
                        title:
                            "온도: ${value[2].toString()}, 습도: ${value[3].toString()}",
                        desc: value.toString())
                    .show();
              }
              if (cmd == 0x54) {
                Alert(
                  context: context,
                  title: "시간이 상적으로 설정되었습니다.",
                  desc: "${value[2].toString()}시 ${value[3].toString()}분",
                ).show();
              }
              if (cmd == 0x51) {
                Alert(
                        context: context,
                        title: "사운드가 정상적으로 출력되었습니다.",
                        desc: value.toString())
                    .show();
              }
              if (cmd == 0x4D) {
                Alert(
                        context: context,
                        title:
                            "문상태: ${value[2].toString()}, 열전소자: ${value[3].toString()}",
                        desc: value.toString())
                    .show();
              }
            }

            flag = false;
          }
        });

        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Characteristic'),
                Text(
                    '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                    style: Theme.of(context).textTheme.body1.copyWith(
                        color: Theme.of(context).textTheme.caption.color))
              ],
            ),
            subtitle: Text(value.toString()),
            contentPadding: EdgeInsets.all(0.0),
          ),
          children: <Widget>[
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('ID 변경'),
              ),
              onTap: () async {
                int id;
                await Alert(
                  context: context,
                  title: '설정할 ID(0x04~0xFE)',
                  content: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 20.0),
                        SizedBox(height: 10.0),
                        TextField(
                          controller: myController,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                  buttons: [
                    DialogButton(
                        child: Text('Save',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        onPressed: () async {
                          Navigator.pop(context, false);
                          print("aa ${myController.text}");
                          id = int.parse(myController.text);
                        }),
                    DialogButton(
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ).show();
                cmd = 0x49;
                await characteristic
                    .write([0x02, cmd, id, 0x00, crc(cmd, id, 0x00), 0x03]);
                flag = true;
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('온도, 습도 설정'),
              ),
              onTap: () async {
                await Alert(
                  context: context,
                  title: '온습도 설정',
                  content: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 20.0),
                        Text('Temp (10 ~ 50C)'),
                        SizedBox(height: 10.0),
                        TextField(
                          controller: tempController,
                        ),
                        SizedBox(height: 10.0),
                        Text('Humidity(10 ~ 90%)'),
                        SizedBox(height: 10.0),
                        TextField(
                          controller: humController,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                  buttons: [
                    DialogButton(
                        child: Text('Save',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        onPressed: () async {
                          Navigator.pop(context, false);
                          temp = int.parse(tempController.text);
                          hum = int.parse(humController.text);
                        }),
                    DialogButton(
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ).show();

                cmd = 0x53;
                await characteristic
                    .write([0x02, cmd, temp, hum, crc(cmd, temp, hum), 0x03]);
                flag = true;
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('온도, 습도 데이터 요구'),
              ),
              onTap: () async {
                cmd = 0x44;
                await characteristic
                    .write([0x02, cmd, 0x01, 0x00, crc(cmd, 0x01, 0x00), 0x03]);
                flag = true;
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('시간 설정'),
              ),
              onTap: () async {
                int hh;
                int mm;
                await Alert(
                  context: context,
                  title: '시간 설정',
                  content: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 20.0),
                        Text('시간'),
                        SizedBox(height: 10.0),
                        TextField(
                          controller: hhController,
                        ),
                        SizedBox(height: 10.0),
                        Text('분'),
                        SizedBox(height: 10.0),
                        TextField(
                          controller: mmController,
                        ),
                        SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                  buttons: [
                    DialogButton(
                        child: Text('Save',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                        onPressed: () async {
                          Navigator.pop(context, false);
                          hh = int.parse(hhController.text);
                          mm = int.parse(mmController.text);
                        }
                      ),
                    DialogButton(
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ).show();
                cmd = 0x54;
                await characteristic
                    .write([0x02, cmd, hh, mm, crc(cmd, hh, mm), 0x03]);
                flag = true;
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('사운드 출력'),
              ),
              onTap: () async {
                cmd = 0x51;
                await characteristic
                    .write([0x02, cmd, 0x01, 0x00, crc(cmd, 0x01, 0x00), 0x03]);
                flag = true;
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Text('기기 상태'),
              ),
              onTap: () async {
                cmd = 0x4D;
                await characteristic
                    .write([0x02, cmd, 0x01, 0x00, crc(cmd, 0x01, 0x00), 0x03]);
                flag = true;
              },
            ),
            IconButton(
              icon: Icon(
                  characteristic.isNotifying ? Icons.sync_disabled : Icons.sync,
                  color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
              onPressed: onNotificationPressed,
            )
          ],
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;

  const DescriptorTile(
      {Key key, this.descriptor, this.onReadPressed, this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .body1
                  .copyWith(color: Theme.of(context).textTheme.caption.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key key, @required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }
}
