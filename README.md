# landscape

Act your mobile phones as landscape.

## Remote Control Apis

### ScrollTextConfiguration

#### Properties

- **text** (`String`): The text content to be displayed. This is a required field.
- **direction** (`String?`): The direction in which the text should scroll. Possible values are `"ltr"`, `"rtl"`.
- **fontSize** (`double?`): The font size of the text.
- **scrollSpeed** (`double?`): The speed at which the text should scroll.
- **fontColor** (`int?`): The color of the text in ARGB format.
- **adaptiveColor** (`bool?`): Whether the text color should adapt to the display mode (dark mode or light mode), this will override the color settings.

#### Example Usage

```shell
# 192.168.1.8 is the IP address of you mobile phone
curl 192.168.1.8:8080/configure/scroll-text -X POST -H "Content-Type: application/json" -d '{"text":"Hello this is kuromesi speaking!", "fontSize":100}'
```