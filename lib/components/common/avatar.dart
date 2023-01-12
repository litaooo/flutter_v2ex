import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CAvatar extends StatelessWidget {
  final String url;
  final double size;
  final int radius = 50;

  const CAvatar({Key? key, required this.url, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl:
            'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202106%2F05%2F20210605015054_1afb0.thumb.1000_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1676034634&t=a66f33b968f7f967882d40e0a3bc3055',
        // imageUrl:
        //     'https://www.gravatar.com/avatar/fc13bfe304918c2fd608450867839de8?s=98&d=retro',
        height: size,
        width: size,
        fit: BoxFit.cover,
        fadeOutDuration: const Duration(milliseconds: 800),
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          // color: Colors.grey,
        ),
      ),
    );
  }
}
