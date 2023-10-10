import 'package:flutter_test/flutter_test.dart';

import 'package:simple_architecture/simple_architecture.dart';

void main() {
  setUpAll($.purgeAll);

  test("Settings should be added", () {
    $.settings.add(
      SampleSetting(
        string: "text",
        float: 3.14,
        integer: 42,
        boolean: true,
        dateTime: DateTime(2023, 10, 6, 21, 36),
      ),
    );
  });

  test("Settings should be readable", () {
    final sampleSetting = $.settings.get<SampleSetting>();

    expect(sampleSetting.string, "text");
    expect(sampleSetting.float, 3.14);
    expect(sampleSetting.integer, 42);
    expect(sampleSetting.boolean, true);
    expect(sampleSetting.dateTime, DateTime(2023, 10, 6, 21, 36));
  });

  test("Settings should be replaceable", () {
    $.settings.replace(SampleSetting(
      boolean: false,
      dateTime: DateTime(2000),
      float: 0.1,
      integer: 1,
      string: "",
    ));

    final sampleSetting = $.settings.get<SampleSetting>();

    expect(sampleSetting.string, "");
    expect(sampleSetting.float, 0.1);
    expect(sampleSetting.integer, 1);
    expect(sampleSetting.boolean, false);
    expect(sampleSetting.dateTime, DateTime(2000));
  });

  test("Settings should not be overriden with add", () {
    expect(
      () => $.settings.add(SampleSetting(
        boolean: false,
        dateTime: DateTime(2000),
        float: 0.1,
        integer: 1,
        string: "",
      )),
      throwsA(const TypeMatcher<DuplicatedElementException>()),
    );
  });

  test("Settings should exist on get or throw exception", () {
    expect(
      () => $.settings.get<NonRegisteredSetting>(),
      throwsA(const TypeMatcher<ElementNotFoundException>()),
    );
  });

  test("Settings should exist on replace or throw exception", () {
    expect(
      () => $.settings.replace(const NonRegisteredSetting()),
      throwsA(const TypeMatcher<ElementNotFoundException>()),
    );
  });
}

final class SampleSetting {
  const SampleSetting({
    required this.string,
    required this.float,
    required this.integer,
    required this.boolean,
    required this.dateTime,
  });

  final String string;
  final double float;
  final int integer;
  final bool boolean;
  final DateTime dateTime;
}

final class NonRegisteredSetting {
  const NonRegisteredSetting();
}
