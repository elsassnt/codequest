import '../models/mission.dart';

/// Data 5 misi. Koordinat: x ke kanan, y ke bawah, dimulai dari (0,0) kiri-atas.
final List<Mission> kMissions = [
  const Mission(
    id: 1,
    title: 'Kenalan dengan Py',
    description:
        'Bawa Py ke bendera. Simpan jumlah langkah di sebuah variabel!',
    material:
        'VARIABEL & TIPE DATA\n\nVariabel adalah wadah untuk menyimpan nilai.\n\n'
        'langkah = 5\n\nTanda = artinya "simpan nilai 5 ke dalam langkah". '
        'Variabel bisa dipakai di perintah:\n\npy.gerak_kanan(langkah)\n\n'
        'Tipe data dasar:\n• Angka: 5, 3.14\n• Teks: "Py"\n• Boolean: True / False\n\n'
        'Perintah gerak: py.gerak_kanan(), py.gerak_kiri(), py.gerak_atas(), '
        'py.gerak_bawah(). Isi angka di dalam kurung untuk jumlah langkah.',
    gridW: 6,
    gridH: 3,
    startX: 0,
    startY: 1,
    finishX: 5,
    finishY: 1,
    coins: [Pt(2, 1), Pt(4, 1)],
    optimalLines: 2,
    starterCode: '# Simpan jumlah langkah di variabel\n',
    hints: [
      'Py perlu bergerak ke kanan sampai bendera.',
      'Simpan jumlah langkah di variabel, lalu pakai variabel itu di dalam py.gerak_kanan().',
      'Coba: langkah = 5 lalu py.gerak_kanan(langkah)',
    ],
    requiredPattern: r'^\s*[A-Za-z_]\w*\s*=(?!=)',
    requiredMessage: 'Misi ini harus memakai variabel (contoh: langkah = 5).',
  ),
  const Mission(
    id: 2,
    title: 'Hitung Langkah',
    description:
        'Gunakan operator hitung (+, -, *, /) untuk menentukan jumlah langkah Py.',
    material:
        'OPERATOR & EKSPRESI\n\nOperator aritmatika: + - * /\nOperator perbandingan: == != < > <= >=\n\n'
        'Ekspresi adalah gabungan nilai dan operator, contoh:\n2 * 2  → 4\n6 - 3  → 3\n\n'
        'Ekspresi boleh langsung dipakai di perintah:\npy.gerak_kanan(2 * 2)',
    gridW: 6,
    gridH: 4,
    startX: 0,
    startY: 0,
    finishX: 4,
    finishY: 3,
    coins: [Pt(2, 0), Pt(4, 2)],
    obstacles: [Pt(1, 2), Pt(2, 2), Pt(3, 2)],
    optimalLines: 2,
    hints: [
      'Py harus ke kanan dulu, baru ke bawah.',
      'Jumlah langkah bisa berupa ekspresi, misalnya 2 * 2.',
      'Ke kanan 4 langkah (2 * 2), ke bawah 3 langkah (6 - 3).',
    ],
    requiredPattern: r'[+\-*/]',
    requiredMessage: 'Misi ini harus memakai operator (+, -, *, atau /).',
  ),
  const Mission(
    id: 3,
    title: 'Persimpangan',
    description:
        'Jalan lurus terhalang batu. Pakai if untuk memilih jalur atas!',
    material:
        'PERCABANGAN (if - else)\n\nif kondisi:\n    perintah_jika_benar\nelse:\n    perintah_jika_salah\n\n'
        'Perintah di dalam if harus menjorok 4 spasi (indentasi). '
        'Gunakan tombol Tab di keyboard coding.\n\n'
        'Contoh:\nenergi = 7\nif energi > 5:\n    py.gerak_atas()',
    gridW: 5,
    gridH: 3,
    startX: 0,
    startY: 1,
    finishX: 4,
    finishY: 1,
    coins: [Pt(2, 0)],
    obstacles: [Pt(1, 1), Pt(2, 1), Pt(3, 1)],
    optimalLines: 5,
    starterCode: '# Jika energi cukup, Py lewat jalur atas\nenergi = 7\n',
    hints: [
      'Jalur tengah terhalang batu. Cari jalan memutar lewat atas.',
      'Gunakan if energi > 5: lalu tulis perintah gerak di bawahnya dengan indentasi.',
      'atas 1x, kanan 4x, lalu bawah 1x — semuanya di dalam if.',
    ],
    requiredPattern: r'^\s*if\b',
    requiredMessage: 'Misi ini harus memakai percabangan if.',
  ),
  const Mission(
    id: 4,
    title: 'Putaran Ajaib',
    description: 'Tangga ini berulang. Pakai perulangan supaya kodenya pendek!',
    material:
        'PERULANGAN (for & while)\n\nfor i in range(4):\n    py.gerak_kanan()\n\n'
        'Artinya: ulangi perintah di dalamnya 4 kali.\n\n'
        'while kondisi:\n    perintah\n\nUlangi selama kondisi masih benar. '
        'Contoh: while py.x < 4:\n\nHati-hati loop tak berhingga!',
    gridW: 5,
    gridH: 5,
    startX: 0,
    startY: 0,
    finishX: 4,
    finishY: 4,
    coins: [Pt(1, 1), Pt(2, 2), Pt(3, 3)],
    obstacles: [
      Pt(0, 1),
      Pt(1, 2),
      Pt(2, 3),
      Pt(3, 4),
      Pt(2, 0),
      Pt(3, 1),
      Pt(4, 2)
    ],
    optimalLines: 3,
    hints: [
      'Lihat polanya: kanan, bawah, kanan, bawah, ...',
      'Masukkan pola kanan + bawah ke dalam for i in range(n).',
      'for i in range(4): lalu py.gerak_kanan() dan py.gerak_bawah() di dalamnya.',
    ],
    requiredPattern: r'^\s*(for|while)\b',
    requiredMessage: 'Misi ini harus memakai perulangan (for atau while).',
  ),
  const Mission(
    id: 5,
    title: 'Fungsi Tangga',
    description:
        'Buat fungsi untuk satu anak tangga, lalu panggil berulang kali.',
    material:
        'FUNGSI (def)\n\nFungsi adalah kumpulan perintah yang diberi nama.\n\n'
        'def tangga():\n    py.gerak_kanan()\n    py.gerak_atas()\n\n'
        'Fungsi baru berjalan saat dipanggil:\ntangga()\n\n'
        'Fungsi + perulangan membuat kode lebih ringkas.',
    gridW: 5,
    gridH: 5,
    startX: 0,
    startY: 4,
    finishX: 4,
    finishY: 0,
    coins: [Pt(1, 3), Pt(2, 2), Pt(3, 1)],
    obstacles: [
      Pt(0, 3),
      Pt(1, 2),
      Pt(2, 1),
      Pt(3, 0),
      Pt(2, 4),
      Pt(3, 3),
      Pt(4, 2)
    ],
    optimalLines: 5,
    hints: [
      'Satu anak tangga = kanan lalu atas.',
      'Buat def tangga(): berisi gerak kanan dan atas, lalu panggil tangga().',
      'def tangga(): ... lalu for i in range(4): tangga()',
    ],
    requiredPattern: r'^\s*def\b',
    requiredMessage: 'Misi ini harus membuat fungsi dengan def.',
  ),
];