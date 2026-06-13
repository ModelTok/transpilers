from fmt.color import fmt, fg, bg, rgb, color, emphasis, terminal_color, text_style
from gtest-extra import EXPECT_EQ, EXPECT_WRITE

def test_format():
    EXPECT_EQ(fmt.format(fg(rgb(255, 20, 30)), "rgb(255,20,30)"),
              "\x1b[38;2;255;020;030mrgb(255,20,30)\x1b[0m")
    EXPECT_EQ(fmt.format(fg(color.blue), "blue"),
              "\x1b[38;2;000;000;255mblue\x1b[0m")
    EXPECT_EQ(
        fmt.format(fg(color.blue) | bg(color.red), "two color"),
        "\x1b[38;2;000;000;255m\x1b[48;2;255;000;000mtwo color\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.bold, "bold"), "\x1b[1mbold\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.faint, "faint"), "\x1b[2mfaint\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.italic, "italic"),
              "\x1b[3mitalic\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.underline, "underline"),
              "\x1b[4munderline\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.blink, "blink"), "\x1b[5mblink\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.reverse, "reverse"),
              "\x1b[7mreverse\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.conceal, "conceal"),
              "\x1b[8mconceal\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.strikethrough, "strikethrough"),
              "\x1b[9mstrikethrough\x1b[0m")
    EXPECT_EQ(
        fmt.format(fg(color.blue) | emphasis.bold, "blue/bold"),
        "\x1b[1m\x1b[38;2;000;000;255mblue/bold\x1b[0m")
    EXPECT_EQ(fmt.format(emphasis.bold, "bold error"),
              "\x1b[1mbold error\x1b[0m")
    EXPECT_EQ(fmt.format(fg(color.blue), "blue log"),
              "\x1b[38;2;000;000;255mblue log\x1b[0m")
    EXPECT_EQ(fmt.format(text_style(), "hi"), "hi")
    EXPECT_EQ(fmt.format(fg(terminal_color.red), "tred"),
              "\x1b[31mtred\x1b[0m")
    EXPECT_EQ(fmt.format(bg(terminal_color.cyan), "tcyan"),
              "\x1b[46mtcyan\x1b[0m")
    EXPECT_EQ(fmt.format(fg(terminal_color.bright_green), "tbgreen"),
              "\x1b[92mtbgreen\x1b[0m")
    EXPECT_EQ(fmt.format(bg(terminal_color.bright_magenta), "tbmagenta"),
              "\x1b[105mtbmagenta\x1b[0m")
    EXPECT_EQ(fmt.format(fg(terminal_color.red), "{}", "foo"),
              "\x1b[31mfoo\x1b[0m")

def test_format_to():
    var out = String()
    fmt.format_to(out, fg(rgb(255, 20, 30)),
                 "rgb(255,20,30){}{}{}", 1, 2, 3)
    EXPECT_EQ(fmt.to_string(out),
              "\x1b[38;2;255;020;030mrgb(255,20,30)123\x1b[0m")

def test_print():
    EXPECT_WRITE(stdout, fmt.print(fg(rgb(255, 20, 30)), "rgb(255,20,30)"),
                 "\x1b[38;2;255;020;030mrgb(255,20,30)\x1b[0m")