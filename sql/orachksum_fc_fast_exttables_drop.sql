DROP DIRECTORY "&&orachk_obj_dir.";
DROP TABLE "&&orachk_obj_tab1.";
DROP TABLE "&&orachk_obj_tab2.";

HOS rm -f &&orachk_path_tabfile1. &&orachk_path_tabfile2.

UNDEF orachk_obj_dir
UNDEF orachk_obj_tab1
UNDEF orachk_obj_tab2
UNDEF orachk_obj_tabfile1
UNDEF orachk_obj_tabfile2
UNDEF orachk_path_tabfile1
UNDEF orachk_path_tabfile2