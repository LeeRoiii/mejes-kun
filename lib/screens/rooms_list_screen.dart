import 'package:flutter/material.dart';
import '../models/room.dart';
import '../database_helper.dart';

class RoomsListScreen extends StatefulWidget {
  @override
  _RoomsListScreenState createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  List<Room> rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final roomsList = await DatabaseHelper.instance.getAllRooms();
    setState(() {
      rooms = roomsList;
    });
  }

  void _showAddRoomDialog() {
    final TextEditingController roomNameController = TextEditingController();
    final TextEditingController roomRentController = TextEditingController();
    final TextEditingController maxOccupantsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNameController,
                decoration: InputDecoration(labelText: 'Room Name'),
              ),
              TextField(
                controller: roomRentController,
                decoration: InputDecoration(labelText: 'Room Rent'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: maxOccupantsController,
                decoration: InputDecoration(labelText: 'Max Occupants per Room'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final roomName = roomNameController.text;
                final roomRent = double.tryParse(roomRentController.text) ?? 0;
                final maxOccupants = int.tryParse(maxOccupantsController.text) ?? 0;

                if (roomName.isNotEmpty && maxOccupants > 0) {
                  final newRoom = Room(
                    name: roomName,
                    rent: roomRent,
                    maxOccupants: maxOccupants,
                    occupants: [],
                  );

                  await DatabaseHelper.instance.addRoom(newRoom);
                  _loadRooms();

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddOccupantDialog(Room room) async {
    final tenantsWithoutRooms = await DatabaseHelper.instance.getTenantsWithoutRooms();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Occupant'),
          content: tenantsWithoutRooms.isEmpty
              ? Text('No available tenants without rooms.')
              : Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tenantsWithoutRooms.length,
                    itemBuilder: (context, index) {
                      final tenant = tenantsWithoutRooms[index];
                      return Card(
                        child: ListTile(
                          title: Text(tenant.name),
                          subtitle: Text(tenant.email),
                          onTap: () async {
                            final shouldAdd = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Confirm Addition'),
                                  content: Text('Are you sure you want to add ${tenant.name} to this room?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('Yes'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldAdd == true) {
                              tenant.roomId = room.id;
                              await DatabaseHelper.instance.updateTenant(tenant);

                              setState(() {
                                room.occupants.add(tenant.name);
                              });

                              await DatabaseHelper.instance.updateRoom(room);
                              _loadRooms();
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showRoomOptions(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('View More Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showRoomDetails(room);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Room Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditRoomDialog(room);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Room'),
              onTap: () async {
                final confirmed = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete ${room.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  await DatabaseHelper.instance.deleteRoom(room.id!);
                  _loadRooms();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRoomDetails(Room room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Room Details'),
          content: Text(
            'Room Name: ${room.name}\n'
            'Rent: \$${room.rent.toStringAsFixed(2)}\n'
            'Max Occupants: ${room.maxOccupants}\n'
            'Current Occupants: ${room.occupants.join(', ')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEditRoomDialog(Room room) {
    final TextEditingController roomNameController = TextEditingController(text: room.name);
    final TextEditingController roomRentController = TextEditingController(text: room.rent.toString());
    final TextEditingController maxOccupantsController = TextEditingController(text: room.maxOccupants.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Room Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNameController,
                decoration: InputDecoration(labelText: 'Room Name'),
              ),
              TextField(
                controller: roomRentController,
                decoration: InputDecoration(labelText: 'Room Rent'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: maxOccupantsController,
                decoration: InputDecoration(labelText: 'Max Occupants per Room'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final roomName = roomNameController.text;
                final roomRent = double.tryParse(roomRentController.text) ?? 0;
                final maxOccupants = int.tryParse(maxOccupantsController.text) ?? 0;

                if (roomName.isNotEmpty && maxOccupants > 0) {
                  final confirmed = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Confirm Edit'),
                        content: Text('Are you sure you want to save these changes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    final updatedRoom = room.copyWith(
                      name: roomName,
                      rent: roomRent,
                      maxOccupants: maxOccupants,
                    );

                    await DatabaseHelper.instance.updateRoom(updatedRoom);
                    _loadRooms();

                    Navigator.of(context).pop();
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rooms List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddRoomDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isFull = room.occupants.length >= room.maxOccupants;

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(room.name),
              subtitle: Text(
                'Rent: \$${room.rent.toStringAsFixed(2)}, Occupants: ${room.occupants.length} / ${room.maxOccupants}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'Add Occupant':
                      _showAddOccupantDialog(room);
                      break;
                    case 'Room Options':
                      _showRoomOptions(room);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Add Occupant',
                      child: Text('Add Occupant'),
                    ),
                    PopupMenuItem<String>(
                      value: 'Room Options',
                      child: Text('Room Options'),
                    ),
                  ];
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
