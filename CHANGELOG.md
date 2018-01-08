## 0.3.1 (2018-01-08)

### Features

* New functions for working with PBSockets
    * `PBSocket.list_keys/2`
    * `PBSocket.list_keys!/2`
* Allow additional options to be passed to `PBSocket.start_link/1`.
* Typespec updates.

## 0.3.0 (2017-11-14)

This release adds a lot of functions to support Riak's non-crdt conflict
resolutions.

### Breaking changes

#### `Object.get_update_metadata/1` now returns `{:ok, metadata}` or `{:error, SiblingError.t}` instead of just `metadata`.

When there are siblings on the object, the underlying
`:riakc_obj.get_update_metadata/1` would throw `:siblings`, making the API
inconsistent and difficult to work with. `Object.get_update_metadata/1` now
behaves like `Object.get_metadata/1`. There is also a new
`Object.get_update_metadata!/1` that raises a `ExRiak.SiblingsError` if there
is a conflict.

### Features
* New functions for working with objects
    * `Object.bucket/1`
    * `Object.bucket_type/1`
    * `Object.get_contents/1`
    * `Object.get_metadatas/1`
    * `Object.get_user_metadata_entry/3`
    * `Object.get_values/1`
    * `Object.key/1`
    * `Object.siblings?/1`
    * `Object.set_vclock/2`
    * `Object.only_bucket/1`
    * `Object.update_value/3`
    * `Object.value_count/1`
    * `Object.vclock/1`

* New functions for working with PBSockets
    * `PBSocket.get!/3`
    * `PBSocket.fetch_type!/3`
    * `PBSocket.fetch_type/3`

* New Metadata module for working with metadata objects
    * `Metadata.get_content_type/1`
    * `Metadata.clear_user_entries/1`
    * `Metadata.delete_user_entry/2`
    * `Metadata.get_user_entries/1`
    * `Metadata.get_user_entry/1`
    * `Metadata.set_user_entry/2`

## 0.2.0 (2017-11-06)

### Features

* New functions for working with objects
    * `Object.new/2`
    * `Object.new/3`
    * `Object.new/4`
    * `Object.update_value/2`
    * `Object.get_update_value!/1`
    * `Object.get_update_value/1`
    * `Object.get_update_content_type!/1`
    * `Object.get_update_content_type/1`
    * `Object.update_content_type/1`
* New functions for working with metadata
    * `Object.get_update_metadata/1`
    * `Object.update_metadata/1`
    * `Object.get_user_metadata_entries/1`
    * `Object.get_user_metadata_entry/2`
    * `Object.set_user_metadata_entry/2`
    * `Object.delete_user_metadata_entry/2`
    * `Object.clear_user_metadata_entries/1`
* New functions for working with PBSockets
    * `PBSocket.start_link/1`
    * `PBSocket.delete/1`
    * `PBSocket.delete!/1`
* Can now configure default hostname and default port to be used with
  `PBSocket.start_link/1` via application config.

### Bugfixes

* Fixed `Object.get_content_type/1` (and related functions) to document returning
  `:undefined` when a content type has not been set.
* Catch when `:riakc_pb_socket` throws `:no_value` during `PBSocket.put/2`


## 0.1.0 (2017-11-03)
Initial release.

### Features

* Get and put objects in riak bucket.
    * `PBSocket.get/3`
    * `PBSocket.put/2`
    * `PBSocket.put!/2`
* Get value, metadata and content type from Object. Values are deserialized into
  Elixir types (like String instead of Charlist) and exceptions are raised on
  the bang functions if there are siblings.
    * `Object.get_content_type!/1`
    * `Object.get_content_type/1`
    * `Object.get_content_types/1`
    * `Object.get_metadata!/1`
    * `Object.get_metadata/1`
    * `Object.get_value!/1`
    * `Object.get_value/1`
