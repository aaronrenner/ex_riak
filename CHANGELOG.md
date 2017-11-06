## Unreleased

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
