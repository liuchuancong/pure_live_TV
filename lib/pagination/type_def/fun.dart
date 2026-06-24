typedef FetchRemote<T> = Future<List<T>> Function(int page, int pageSize);
typedef FetchAllData<T> = Future<List<T>> Function();
typedef FetchFixedSize<T> = Future<List<T>> Function(int bigPage, int fixedServerSize);
