import 'package:flutter_test/flutter_test.dart';

import 'package:simple_architecture/simple_architecture.dart';

enum TestFailure {
  failure1,
  failure2,
}

void main() {
  test("Response success should work", () {
    const r = Success<bool, TestFailure>(true);

    expect(r.isSuccess, true);
    expect(r.isFailure, false);
    expect(r.value, true);
    expect(() => r.failure, throwsA(isA<TypeError>()));
    expect(r.stackTrace, null);
    expect(() => r.ensureSuccess(), isA<void>());
  });

  test("Response failure should work", () {
    const r = Failure<bool, TestFailure>(
      TestFailure.failure1,
      FormatException(),
    );

    expect(r.isSuccess, false);
    expect(r.isFailure, true);
    expect(() => r.value, throwsA(isA<TypeError>()));
    expect(r.stackTrace, null);
    expect(() => r.ensureSuccess(), throwsA(isA<FormatException>()));
  });

  test("Union types should work", () {
    const Response<bool, TestFailure> s = Success<bool, TestFailure>(true);

    switch (s) {
      case Failure():
        fail("Should not be Failure here");
      default:
        expect(true, s.value);
    }

    const Response<bool, TestFailure> f = Failure<bool, TestFailure>(
      TestFailure.failure2,
      FormatException(),
    );

    switch (f) {
      case Success():
        fail("Should not be Success here");
      default:
        expect(TestFailure.failure2, f.failure);
    }
  });

  test("Value equality should work", () {
    final dt = DateTime.now().millisecondsSinceEpoch;
    final success1 = Success<bool, TestFailure>(dt == dt);
    final success2 = Success<bool, TestFailure>(dt == dt);
    final success3 = Success<bool, TestFailure>(dt != dt);

    expect(success1 == success2, true);
    expect(success2 == success3, false);

    final failure1 = Failure<bool, TestFailure>(
      dt == dt ? TestFailure.failure1 : TestFailure.failure2,
    );

    final failure2 = Failure<bool, TestFailure>(
      dt == dt ? TestFailure.failure1 : TestFailure.failure2,
    );

    final failure3 = Failure<bool, TestFailure>(
      dt != dt ? TestFailure.failure1 : TestFailure.failure2,
    );

    expect(failure1 == failure2, true);
    expect(failure1 == failure3, false);
  });

  test("ToString should work", () {
    const success = Success<bool, TestFailure>(true);

    expect(success.toString(), "Success<bool>(true)");

    late Response<bool, TestFailure> failure;

    try {
      throw UnimplementedError();
    } catch (ex, stackTrace) {
      failure = Failure(TestFailure.failure1, ex, stackTrace);
    }

    expect(
      failure.toString(),
      "Failure<TestFailure>(TestFailure.failure1) [UnimplementedError]",
    );

    const failure2 = Failure<bool, TestFailure>(TestFailure.failure2);

    expect(failure2.toString(), "Failure<TestFailure>(TestFailure.failure2)");
  });

  test("HashCode should not be 0", () {
    const success = Success<bool, TestFailure>(false);

    expect(success.hashCode, isNot(0));
  });

  test("Ensure success should work", () {
    const failure1 = Failure<bool, TestFailure>(TestFailure.failure1);

    expect(() => failure1.ensureSuccess(), throwsA(isA<TestFailure>()));

    late Failure<bool, TestFailure> failure2;

    try {
      throw const FormatException();
    } catch (ex, stackTrace) {
      failure2 = Failure<bool, TestFailure>(
        TestFailure.failure1,
        ex,
        stackTrace,
      );
    }

    expect(() => failure2.ensureSuccess(), throwsA(isA<FormatException>()));

    late Failure<bool, TestFailure> failure3;

    try {
      throw const FormatException();
    } catch (ex) {
      failure3 = Failure<bool, TestFailure>(
        TestFailure.failure1,
        ex,
      );
    }

    expect(() => failure3.ensureSuccess(), throwsA(isA<FormatException>()));
  });

  test("Copy failure should work", () {
    const f1 = Failure<bool, TestFailure>(TestFailure.failure1);
    final f2 = Failure<int, TestFailure>.from(f1);

    expect(f1.failure, TestFailure.failure1);
    expect(f2.failure, TestFailure.failure1);
  });
}
