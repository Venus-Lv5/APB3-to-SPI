
#!/usr/bin/env perl
use strict;
use warnings;

# ============================================================
#  CONFIG
# ============================================================

# File testcase mẫu (đang tương ứng: non, 8bit, cpol0, cpha0, slave0)
my $template_file = "spi_non_8bit_cpol0_cpha0_slave0_test.sv";

# File package chứa list testcase
my $pkg_file      = "test_pkg.sv";

# Các giá trị cần quét
my @WORDS  = (8, 16);           # 8 / 16 bit
my @CPOLS  = (0, 1);            # cpol 0 / 1
my @CPHAS  = (0, 1);            # cpha 0 / 1
my @CDTES  = (0, 1);            # 0 = non (cdte off), 1 = en (cdte on)
my @SLAVES = (0, 1, 2, 3);      # slave0..3

# ============================================================
#  HÀM TIỆN ÍCH: ĐỌC / GHI FILE
# ============================================================

sub read_file {
    my ($fname) = @_;
    open my $fh, "<", $fname or die "Cannot open $fname for read: $!\n";
    local $/;               # undef -> đọc hết 1 lần
    my $txt = <$fh>;
    close $fh;
    return $txt;
}

sub write_file {
    my ($fname, $txt) = @_;
    open my $fh, ">", $fname or die "Cannot open $fname for write: $!\n";
    print $fh $txt;
    close $fh;
}

# ============================================================
#  LẤY TÊN CLASS GỐC TỪ TEMPLATE
# ============================================================

my $template = read_file($template_file);

# Tìm tên class theo pattern: class <TênClass> extends ...
my ($base_name) = $template =~ /class\s+(\w+)\s+extends/;
die "Không tìm được tên class trong $template_file\n" unless $base_name;

print "Base test class name: $base_name\n";

# ============================================================
#  SINH TẤT CẢ TESTCASE
# ============================================================

my @generated_files;   # chỉ lưu những file MỚI tạo để update test_pkg.sv

for my $cdte (@CDTES) {
    for my $word (@WORDS) {
        for my $cpol (@CPOLS) {
            for my $cpha (@CPHAS) {
                for my $sid (@SLAVES) {

                    # cdte: 0 -> non, 1 -> en
                    my $cdte_str = $cdte ? "en" : "non";
                    my $word_str = "${word}bit";

                    # Tên class + tên file theo format bạn yêu cầu
                    # spi_non_8bit_cpol0_cpha0_slave0_test
                    my $test_name = sprintf(
                        "spi_%s_%s_cpol%d_cpha%d_slave%d_test",
                        $cdte_str, $word_str, $cpol, $cpha, $sid
                    );
                    my $file_name = "$test_name.sv";

                    # Không đè lên file template gốc
                    if ($file_name eq $template_file) {
                        print "Skip template itself: $file_name\n";
                        next;
                    }

                    # Không đè lên file đã tồn tại (an toàn)
                    if (-e $file_name) {
                        print "File $file_name đã tồn tại, bỏ qua (không overwrite)\n";
                        next;
                    }

                    # Bắt đầu từ nội dung template
                    my $txt = $template;

                    # 1) Đổi tên class / uvm_component_utils / new(...)
                    #    Thay toàn bộ base_name thành test_name
                    $txt =~ s/\Q$base_name\E/$test_name/g;

                    # 2) Sửa các constraint:
                    #    word == X
                    #    cpol == X
                    #    cpha == X
                    #    cdte == X
                    #    slave_id == X
                    #
                    # Mỗi dòng dùng dạng (tên_field == số) -> thay số
                    $txt =~ s/(word\s*==\s*)\d+/$1$word/;
                    $txt =~ s/(cpol\s*==\s*)\d+/$1$cpol/;
                    $txt =~ s/(cpha\s*==\s*)\d+/$1$cpha/;
                    $txt =~ s/(cdte\s*==\s*)\d+/$1$cdte/;
                    $txt =~ s/(slave_id\s*==\s*)\d+/$1$sid/;

                    # 3) Ghi file mới
                    write_file($file_name, $txt);
                    push @generated_files, $file_name;

                    print "Created $file_name\n";
                }
            }
        }
    }
}

# ============================================================
#  THÊM `include` CÁC TEST MỚI VÀO test_pkg.sv
# ============================================================

if (@generated_files) {
    my $pkg_txt = read_file($pkg_file);
    my $include_block = "";

    for my $f (@generated_files) {
        # Nếu đã được include rồi thì bỏ qua
        next if $pkg_txt =~ /\Q$f\E/;
        $include_block .= "\t`include \"$f\"\n";
    }

    if ($include_block ne "") {
        # Chèn block include ngay trước dòng 'endpackage'
        # ^\s*endpackage  : match dòng có thể có space + endpackage
        my $ok = ($pkg_txt =~ s/^\s*endpackage/$include_block$&/m);

        if ($ok) {
            write_file($pkg_file, $pkg_txt);
            print "Updated $pkg_file with new includes.\n";
        } else {
            warn "Không tìm thấy 'endpackage' trong $pkg_file, không thể chèn include.\n";
        }
    } else {
        print "Không có include mới cần thêm vào $pkg_file.\n";
    }
} else {
    print "Không tạo thêm testcase mới nào (có thể tất cả file đã tồn tại).\n";
}

print "Done.\n";
