library dataconnect_generated;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_movie.dart';

part 'upsert_user.dart';

part 'add_review.dart';

part 'delete_review.dart';

part 'list_movies.dart';

part 'list_users.dart';

part 'list_user_reviews.dart';

part 'get_movie_by_id.dart';

part 'search_movie.dart';

class ExampleConnector {
  CreateMovieVariablesBuilder createMovie({
    required String title,
    required String genre,
    required String imageUrl,
  }) {
    return CreateMovieVariablesBuilder(
      dataConnect,
      title: title,
      genre: genre,
      imageUrl: imageUrl,
    );
  }

  UpsertUserVariablesBuilder upsertUser({
    required String username,
  }) {
    return UpsertUserVariablesBuilder(
      dataConnect,
      username: username,
    );
  }

  AddReviewVariablesBuilder addReview({
    required String movieId,
    required int rating,
    required String reviewText,
  }) {
    return AddReviewVariablesBuilder(
      dataConnect,
      movieId: movieId,
      rating: rating,
      reviewText: reviewText,
    );
  }

  DeleteReviewVariablesBuilder deleteReview({
    required String movieId,
  }) {
    return DeleteReviewVariablesBuilder(
      dataConnect,
      movieId: movieId,
    );
  }

  ListMoviesVariablesBuilder listMovies() {
    return ListMoviesVariablesBuilder(
      dataConnect,
    );
  }

  ListUsersVariablesBuilder listUsers() {
    return ListUsersVariablesBuilder(
      dataConnect,
    );
  }

  ListUserReviewsVariablesBuilder listUserReviews() {
    return ListUserReviewsVariablesBuilder(
      dataConnect,
    );
  }

  GetMovieByIdVariablesBuilder getMovieById({
    required String id,
  }) {
    return GetMovieByIdVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  SearchMovieVariablesBuilder searchMovie() {
    return SearchMovieVariablesBuilder(
      dataConnect,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'morningmate',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}

T nativeFromJson<T>(dynamic json) {
  return json as T;
}

dynamic nativeToJson<T>(T data) {
  return data;
}

enum OptionalState {
  set,
  unset,
}

class Optional<T> {
  T? _value;
  OptionalState state;
  final T Function(dynamic json) fromJson;
  final dynamic Function(T data) toJsonFunc;

  Optional.optional(this.fromJson, this.toJsonFunc)
      : state = OptionalState.unset;

  T? get value => _value;

  set value(T? v) {
    _value = v;
    state = OptionalState.set;
  }

  dynamic toJson() {
    if (state == OptionalState.set) {
      return toJsonFunc(_value as T);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Optional<T>) return false;
    return _value == other._value && state == other.state;
  }

  @override
  int get hashCode => Object.hash(_value, state);
}
