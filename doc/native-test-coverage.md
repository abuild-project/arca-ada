# Native writer predecessor-test mapping

This maps every registered CPIO/TAR test and the shared-helper tests at Abuild
revision `136ca84f0f5c49acae5fdd22f43359a32ca26e70` to Arca checks. It records
equivalent assertions rather than requiring identical method names, fixtures
or Ahven grouping. Normal checks use only committed Arca inputs.

The source units are `tests-abuild_transformations_cpio`,
`tests-abuild_file_formats_tar` and `tests-abuild_file_formats_binary_io`.
Their mixed transformation cases are classified explicitly below. Ahven
checks package contracts; the independent Python suites own byte-format and
external-reader assertions. A case marked adapter-only must remain tested in
Abuild when its backend later changes.

## CPIO

[`cpio_scenarios.adb`](../tests/cpio_scenarios.adb) supplies the shared direct
checks and archive inputs. [`check-cpio.py`](../tests/check-cpio.py) independently
decodes fields, layout and payloads and uses GNU cpio and bsdtar.

| Original registered case | Arca assertion or scope disposition |
| --- | --- |
| `Create_Simple_CPIO` | `check_entries` and `test_external_readers` cover native entry types, metadata and contents. Full transformation `.hex`/`.list` snapshots are replaced by the independent native matrix and short raw-record check; fileset assembly remains in Abuild. |
| `Create_CPIO_Directory_Tree` | Nested native names and external extraction are covered. Automatically adding parent directories from a fileset is adapter-only. |
| `Check_CPIO_Block_Device_Header` | `check_entries`: permission-only input `006` must emit mode `060006`, including writer-supplied type bits. |
| `Check_CPIO_Raw_Record_Layout` | `test_short_raw_records`: five-byte file/symlink data, original field values and offsets, uppercase hex, link count, zero regular rdev fields, NUL names, 1/2/3-byte padding, trailer fields and exact 512-byte size. The general decoder also rejects extra zero blocks. |
| `Reject_Uninitialized_CPIO_Close` | Shared `Check_Errors`, Ahven `CPIO/error contracts`: exception/message before Create and after Close. |
| `Check_CPIO_Content` | Complete patterned payload equality in `check_entries` and after extraction with both readers. Transform creation remains in Abuild. |
| `Check_CPIO_Hardlinks_From_Source_Path` | Explicit writer hardlink headers, one payload and extracted inode identity are covered. Automatic grouping by source path is adapter-only. |
| `Check_CPIO_Hardlinks_From_Inodes` | The same native output contract is covered. Discovering shared source inodes is adapter-only. |
| `Check_CPIO_Hardlink_Metadata` | `check_entries`: equal inode/NLink/mode/UID/GID/mtime, first payload empty and last payload complete. Choosing canonical metadata from contradictory fileset entries is adapter-only. |
| `Create_CPIO_With_Larger_File` | A patterned payload exceeding two copy buffers is independently decoded and extracted with both readers. Transform wiring is adapter-only. |
| `Reject_Pre_Epoch_CPIO_Directory` | The underlying native timestamp rejection is covered. Translation to a contextual `CPIO_Generic_Error` is adapter-only. |
| `Reject_Pre_Epoch_CPIO_Writer_MTime` | Shared `Check_Errors`: UTC epoch minus one second and first timestamp above `Unsigned_32`, with exception/message checks. |
| `Reject_Oversized_CPIO_Writer_File` | The Python fixture supplies exactly `2**32` sparse bytes; shared errors require `File_Too_Big` and its size diagnostic. Ahven also tests a larger rejected source. |
| `Reject_Unopened_CPIO_Add` | All native entry operations are checked before Create. The original `Images.Add_Object` exception translation and message are adapter-only. |
| `Create_CPIO_With_Larger_Than_4GB_File` | The native size boundary is covered as above. Transformation diagnostics containing the entry path are adapter-only. |

The short raw check preserves the assertions formerly hidden by broad
thematic matching. Corruption controls change single-link/rdev fields,
hexadecimal case, three-byte payload padding and total padding. The changed
field values retain a valid record layout, so the value assertions must fail.

## TAR

[`tar_scenarios.adb`](../tests/tar_scenarios.adb) supplies the shared checks and
inputs. [`check-tar.py`](../tests/check-tar.py) uses its own field map and
checksum calculation, the retained GNU fixture, GNU tar and bsdtar.

| Original registered case | Arca assertion or scope disposition |
| --- | --- |
| `Create_Simple_Tarball` | `check_entries` and `test_reference_readers`: every supported type, metadata, device values, payload and links. Fileset assembly stays in Abuild. |
| `Create_Tarball_Parallel` | Ahven and Python compare eight independent complete outputs on 128-KiB worker stacks; the predecessor used twenty workers. |
| `Create_Tarball_With_Longnames` | `check_edges` pins a deep multipart path with several legal splits and a long multipart hardlink target. `test_legacy_reader_edges` lists and extracts both with both readers. Adapter path assembly is excluded. |
| `Create_Tarball_With_Longnames_101` | Exactly 100-byte names and 101-byte GNU fallback are checked independently. The original declared path is actually 100 characters despite the case name. Fileset tree construction stays in Abuild. |
| `Create_Tarball_With_Prefix_Split_Path` | The unchanged GNU fixture pins the original `middle/leaf.txt` split path; both readers list it. |
| `Check_Tar_Header_Format` | `header_fields`, `check_entries` and the complete GNU fixture pin magic/version, fields, checksums, payloads and padding. |
| `Check_Tar_GNU_Ustar_Golden_Master` | `test_gnu_ustar_fixture` compares all bytes to the original unchanged, hash-checked reference fixture. |
| `Check_Tar_Prefix_Header_Fields` | GNU fixture plus explicit 155/100-byte prefix/name checks. The deep-path check also pins the rightmost eligible split. |
| `Check_Tar_Exact_Fit_Header_Fields` | Exact 100-byte name/link and 155-byte prefix fields, no unnecessary GNU metadata, and explicit final types including symlink `2`. |
| `Check_Tar_Long_Directory_Header` | `check_edges` pins `L`, complete name, directory type `5`, truncated fallback name and empty prefix; both readers reconstruct and extract the directory. |
| `Check_Tar_Leading_Slash_Longname` | The original leading-slash long-directory condition requires GNU `L` and preserves the complete name. Absolute-path extraction is not needed by this raw-header assertion. |
| `Check_Tar_End_Of_Archive_Marker` | Empty output is exactly two zero blocks; both readers accept it with an empty listing. Nonempty archives require exactly two end blocks too. |
| `Check_Tar_Directory_Name_Normalization` | `already/` remains unchanged and has final type `5`; existing repeated trailing separators retain the predecessor's actual behavior. |
| `Extract_Tarball_Content` | Both readers extract patterned and empty regular files with exact content. |
| `Extract_Multi_Buffer_Tarball_Content` | `test_aligned_multi_buffer_readers` uses `1 MiB + 512`, checks exact archive length with no payload padding, and compares both extracted files byte for byte. The size matrix also covers unaligned and exact-buffer inputs. |
| `Create_Tarball_With_Long_Link_Target` | Type `2`, full GNU `K` target and raw `././@LongLink` marker are pinned, with actual symlink targets checked after extraction by both readers. |
| `Check_Tar_Long_Name_And_Link` | Combined `L,K` ordering, full metadata, final hardlink type `1`, 100-byte fallback name and target marker. Both readers produce a regular hardlink verified with `lstat`, not a followed symlink. |
| `Check_Tar_Empty_User_Group_Numeric_Fallback` | Empty raw uname/gname plus `test_numeric_owner_fallback`: GNU `tar -tvf` must display `65432/65431` without forced numeric-owner output. |
| `Reject_Missing_Source_File` | Shared `Check_Errors` and decoded recovery output. |
| `Reject_Uninitialized_Archive` | Shared `Check_Errors`: all entry operations and Close. |
| `Reject_Pre_Epoch_Timestamp` | Shared header-time path rejects UTC epoch minus one second; the direct case now uses a device entry. |
| `Reject_Too_Large_Mtime` | First unrepresentable value `2**33`, rather than a date further beyond the boundary. |
| `Accept_Max_Mtime` | `check_entries` pins `2**33 - 1` in the header. |
| `Reject_Too_Large_File` | Sparse `2**33`-byte source and exact exception identity. |
| `Reject_Too_Large_Metadata_Field` | UID, GID, major and minor independently reject their first overflowing value. |
| `Accept_Max_Metadata_Field` | All four seven-octal-digit fields accept `2**21 - 1`; raw values and reader acceptance are checked. |
| `Check_Tarball_Hardlinks_From_Source_Path` | Native explicit hardlinks are covered. Automatic grouping of identical source paths is adapter-only. |
| `Check_Tarball_Hardlinks_From_Inodes` | Native explicit hardlinks are covered. Source inode discovery/grouping is adapter-only. |

TAR corruption controls repair the checksum after changing final types,
fallback names/targets or the selected prefix split. The generic decoder
must first accept the modified layout; only the intended value assertion
then rejects it. External-reader checks use the real archives too.

## Shared copy helper

| Original registered case | Arca assertion or scope disposition |
| --- | --- |
| `Reject_Zero_Size_Copy_Growth` | Private-copy Ahven/shared scenarios reject a nonempty source after a zero-size snapshot, source growth and short reads, and check messages and descriptor cleanup. |
| `Encode_Little_Endian_Fields` | Excluded: these endian operations were not imported into Arca. |
| `Reject_Out_Of_Bounds_Field` | Excluded: this concerns the same non-imported endian operations. |

This mapping covers the relevant original writer assertions. It does not
claim every possible future boundary, exhaustive I/O faults, active-I/O task
abort safety or completion of maximum multi-gigabyte payloads. Arca adds
scope-exit ownership, failed-Create/closed-instance reuse, decoder sensitivity
and reproducibility checks beyond this predecessor mapping.
