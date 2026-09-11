import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/views/bookshelf_view.dart';

void main() {
  test('immediateBoxSpineArts uses Jellyfin Box urls without network', () {
    const tapes = [
      Tape(
        id: 'with-box',
        title: 'Box Tape',
        streamUrl: '',
        boxImageUrl: 'http://jellyfin/Items/with-box/Images/Box',
      ),
      Tape(id: 'plain', title: 'Plain Tape', streamUrl: ''),
    ];

    final arts = immediateBoxSpineArts(tapes);

    expect(arts.keys, ['with-box']);
    expect(arts['with-box']!.imageUrl, contains('/Images/Box'));
    expect(arts.containsKey('plain'), isFalse);
  });
}
