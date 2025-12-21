# Setup Script Generator (GUI)

Tool ini membuat `setup.ps1` secara otomatis dari template, tanpa harus edit manual.

## Cara Pakai

1. Jalankan `gui_tools/gui_setup.ps1`.
2. Atur pilihan dan isi field yang diperlukan.
3. Klik **Generate setup.ps1**.

## File

- `setup_template.ps1`: Template dengan placeholder `${VARIABLE}` dan marker `# <PACKAGE_LIST_MARKER>`.
- `gui_tools/gui_setup.ps1`: GUI untuk mengisi data paket dan menghasilkan `setup.ps1`.
- `gui_tools/gui_setup.xaml`: Layout XAML untuk GUI.
- `package_list.json`: Daftar default paket yang dimuat oleh GUI.
- `url_list.json`: Daftar default installer URL yang dimuat oleh GUI.
- `setup.ps1`: Output hasil generate.
