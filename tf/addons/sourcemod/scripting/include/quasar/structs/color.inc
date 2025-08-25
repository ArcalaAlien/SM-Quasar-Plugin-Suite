#define HUDCOLOR_RED        {255,   0,   0, 255}
#define HUDCOLOR_ORANGE     {255, 125,   0, 255}
#define HUDCOLOR_YELLOW     {255, 255,   0, 255}
#define HUDCOLOR_YGREEN     {125, 255,   0, 255}
#define HUDCOLOR_GREEN      {  0, 255,   0, 255}
#define HUDCOLOR_AQUA       {  0, 255, 125, 255}
#define HUDCOLOR_CYAN       {  0, 255, 255, 255}
#define HUDCOLOR_BGREEN     {  0, 125, 255, 255}
#define HUDCOLOR_BLUE       {  0,   0, 255, 255}
#define HUDCOLOR_PURPLE     {125,   0, 255, 255}
#define HUDCOLOR_PINK       {255,   0, 255, 255}
#define HUDCOLOR_MAGENTA    {255,   0, 125, 255}

#define HUDCOLOR_WHITE      {255, 255, 255, 255}
#define HUDCOLOR_LGREY      {200, 200, 200, 255}
#define HUDCOLOR_MGREY      {150, 150, 150, 255}
#define HUDCOLOR_DGREY      {100, 100, 100, 255}
#define HDUCOLOR_BLACK      {  0,   0,   0, 255}

enum struct QSRColor
{
    char name[128];
    int r;
    int g;
    int b;
    int a;

    void RGBAFromArray(int colors[4])
    {
        this.r = colors[0];
        this.g = colors[1];
        this.b = colors[2];
        this.a = colors[3];
    }

    void RGBFromArray(int colors[3])
    {
        this.r = colors[0];
        this.g = colors[1];
        this.b = colors[2];
    }

    void RGBAToArray(int colors[4])
    {
        colors[0] = this.r;
        colors[1] = this.g;
        colors[2] = this.b;
        colors[3] = this.a;
    }

    void RGBToArray(int colors[3])
    {
        colors[0] = this.r;
        colors[1] = this.g;
        colors[2] = this.b;
    }

    void RGBToString(char[] buffer, int maxlen, const char[] delim=" ")
    {
        FormatEx(buffer, maxlen, "%d%s%d%s%d%s%d", this.r, delim, this.g, delim, this.b);
    }

    void RGBAToString(char[] buffer, int maxlen, const char[] delim=" ")
    {
        FormatEx(buffer, maxlen, "%d%s%d%s%d%s%d", this.r, delim, this.g, delim, this.b, delim, this.a);
    }

    void RGBFromString(const char[] rgb, const char[] delim=" ")
    {
        char colors[3][4];
        ExplodeString(rgb, delim, colors, 3, 4);
        
        this.r = StringToInt(colors[0]);
        this.g = StringToInt(colors[1]);
        this.b = StringToInt(colors[2]);
    }

    void RGBAFromString(const char[] rgba, const char[] delim=" ")
    {
        char colors[4][4];
        ExplodeString(rgba, delim, colors, 4, 4);

        this.r = StringToInt(colors[0]);
        this.g = StringToInt(colors[1]);
        this.b = StringToInt(colors[2]);
        this.a = StringToInt(colors[3]);
    }

    void SetChannel(const int channel, int value)
    {
        switch (channel)
        {
            // Red
            case 0:
            {
                this.r = NormalizeColorChannel(value);
            }

            // Green
            case 1:
            {
                this.g = NormalizeColorChannel(value);
            }

            // Blue
            case 2:
            {
                this.b = NormalizeColorChannel(value);
            }

            // Alpha
            case 3:
            {
                this.a = NormalizeColorChannel(value);
            }
        }
    }

    int ToDecimal()
    {
        return NormalizeColorDecimal((this.r << 16) + (this.g << 8) + (this.b));
    }

    void FromDecimal(const int decimal)
    {
        this.r = NormalizeColorChannel(decimal >> 16 & 0xff);
        this.g = NormalizeColorChannel(decimal >>  8 & 0xff);
        this.b = NormalizeColorChannel(decimal       & 0xff);
    }

    void Normalize()
    {
        this.r = NormalizeColorChannel(this.r);
        this.g = NormalizeColorChannel(this.g);
        this.b = NormalizeColorChannel(this.b);
        this.a = NormalizeColorChannel(this.a);
    }

    void Reset()
    {
        this.name = "";
        this.r = 255;
        this.g = 255;
        this.b = 255;
        this.a = 255;
    }
}

stock int NormalizeColorChannel(int channel)
{
    if      (channel < 0)   { return 0; }
    else if (channel > 255) { return 255; }
    else                    { return channel; }
}

stock int NormalizeColorDecimal(int decimal)
{
    if      (decimal < 0)        { return 0; }
    else if (decimal > 16777215) { return 16777215; }
    else                         { return decimal; }
}