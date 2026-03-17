import 'package:LawyerOnline/component/gallery_view.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class ContentCarousel extends StatefulWidget {
  const ContentCarousel({
    super.key,
    this.code,
    this.url,
    this.model,
    this.urlGallery,
  });

  final String? code;
  final String? url;
  final dynamic model;
  final String? urlGallery;

  @override
  // ignore: library_private_types_in_public_api
  _ContentCarousel createState() => _ContentCarousel();
}

class _ContentCarousel extends State<ContentCarousel> {
  late Future<dynamic> _futureModel;

  // String _urlShared = '';
  List urlImage = [];
  List<ImageProvider> urlImageProvider = [];

  @override
  void initState() {
    super.initState();
    _futureModel =
        post(widget.url!, {'skip': 0, 'limit': 1, 'code': widget.code});
    readGallery();
    // sharedApi();
  }

  Future<dynamic> readGallery() async {
    final result =
        await postObjectData(widget.urlGallery!, {'code': widget.code});

    if (result['status'] == 'S') {
      List data = [];
      List<ImageProvider> dataPro = [];

      for (var item in result['objectData']) {
        data.add(item['imageUrl']);

        dataPro.add(NetworkImage(item['imageUrl']));
      }
      setState(() {
        urlImage = data;
        urlImageProvider = dataPro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _futureModel, // function where you call your api
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        // AsyncSnapshot<Your object type>
        if (snapshot.hasData) {
          // setState(() {
          //   urlImage = [snapshot.data[0].imageUrl];
          // });
          return myContent(
            snapshot.data[0],
          ); //   return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return myContent(
            widget.model,
          );
          // return myContent(widget.model);
        }
      },
    );
  }

  myContent(dynamic model) {
    List image = [model['imageUrl']];
    List<ImageProvider> imagePro = [NetworkImage(model['imageUrl'])];
    return ListView(
      shrinkWrap: true, // 1st add
      physics: const ClampingScrollPhysics(), // 2nd
      children: [
        Container(
          // color: Colors.green,
          padding: const EdgeInsets.only(
            right: 10.0,
            left: 10.0,
          ),
          margin: const EdgeInsets.only(right: 50.0, top: 10.0),
          child: Text(
            '${model['title']}',
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Kanit',
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                right: 10,
                left: 10,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage('${model['imageUrlCreateBy']}'),
                    // child: Image.network(
                    //     '${snapshot.data[0]['imageUrlCreateBy']}'),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${model['createBy']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              dateStringToDate(model['createDate']),
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Kanit',
                              ),
                            ),
                            // Text(
                            //   ' | ' + 'เข้าชม ' + '${model['view']}' + ' ครั้ง',
                            //   style: TextStyle(
                            //     fontSize: 10,
                            //     fontFamily: 'Kanit',
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Container(
            //   width: 74.0,
            //   height: 31.0,
            //   decoration: BoxDecoration(
            //       image: DecorationImage(
            //     image: AssetImage('assets/images/share.png'),
            //   )),
            //   alignment: Alignment.centerRight,
            //   child: FlatButton(
            //     padding: EdgeInsets.all(0.0),
            //     onPressed: () {
            //       final RenderBox box = context.findRenderObject();
            //       Share.share(
            //         _urlShared +
            //             'content/news/' +
            //             '${model['code']}' +
            //             '${model['title']}',
            //         subject: '${model['title']}',
            //         sharePositionOrigin:
            //             box.localToGlobal(Offset.zero) & box.size,
            //       );
            //     },
            //   ),
            // )
          ],
        ),
        Container(
          // width: 500.0,
          color: const Color(0x0fffffff),
          child: GalleryView(
            imageUrl: [...image, ...urlImage],
            imageProvider: [...imagePro, ...urlImageProvider],
          ),
        ),
        Container(
          height: 10,
        ),
        // Image.network('${model['imageUrl']}'),
        // Container(
        //   height: 20,
        // ),
        Padding(
          padding: const EdgeInsets.only(
            right: 10,
            left: 10,
          ),
          child: Html(
            data: model['description'],
            onLinkTap: (String? url, Map<String, String> attributes, element) {
              launch(url!);
            },
          ),
        ),
      ],
    );
  }
}
