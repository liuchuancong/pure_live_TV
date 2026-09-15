enum PagingMode {
  serverRemote, // standard server paging (page + pageSize)
  serverFixedSize, // fixed server page size, paged locally
  serverAll, // server returns everything, paged locally
  localReactive, // local reactive list, paged live
}
