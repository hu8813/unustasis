import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<Map<String, dynamic>> getSupportMap({
    required BuildContext context,
    required String languageCode,
  }) async {
    String data = await DefaultAssetBundle.of(context)
        .loadString("assets/faq_$languageCode.json");
    return jsonDecode(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "settings_support")),
      ),
      body: FutureBuilder(
        future: getSupportMap(
          context: context,
          languageCode: FlutterI18n.currentLocale(context)!.languageCode,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          Map<String, dynamic> faq = snapshot.data!;
          return ListView.builder(
              itemCount: faq.length + 1,
              itemBuilder: (context, index) {
                if (index == faq.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        launchUrl(Uri.parse("https://discord.gg/UEPGY8AG9V"));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.discord_outlined,
                              color: Colors.white,
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Unu Community Discord",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                MapEntry category = faq.entries.elementAt(index);

                return ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  initiallyExpanded: true,
                  iconColor: Colors.white,
                  tilePadding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 8),
                  title: Text(
                    category.key.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    for (MapEntry question in category.value.entries)
                      ExpansionTile(
                          iconColor: Colors.white,
                          tilePadding: const EdgeInsets.only(
                              left: 32, right: 16, top: 8, bottom: 8),
                          title: Text(question.key.toString()),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(32, 0, 16, 32),
                              child: Text(
                                question.value.toString(),
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            )
                          ]),
                  ],
                );
              });
        },
      ),
    );
  }
}
