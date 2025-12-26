<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <html>
            <head>
                <title>Каталог на Вина</title>
                <style>
                    body {
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                        background-color: #f9f9f9;
                        margin: 20px;
                        color: #333;
                    }
                    h1 {
                        text-align: center;
                        color: #722f37;
                        border-bottom: 2px solid #722f37;
                        padding-bottom: 10px;
                    }
                    table {
                        width: 100%;
                        border-collapse: collapse;
                        background-color: white;
                        box-shadow: 0 0 10px rgba(0,0,0,0.1);
                        margin-top: 20px;
                    }
                    th {
                        background-color: #722f37;
                        color: white;
                        padding: 12px;
                        text-align: left;
                    }
                    td {
                        border-bottom: 1px solid #ddd;
                        padding: 15px;
                        vertical-align: middle;
                    }
                    tr:hover {
                        background-color: #f1f1f1;
                    }
                    .wine-img {
                        max-width: 100px;
                        max-height: 150px;
                        border-radius: 4px;
                        box-shadow: 2px 2px 5px rgba(0,0,0,0.2);
                    }
                    .price-tag {
                        font-weight: bold;
                        color: #2c7a2c;
                        font-size: 1.1em;
                    }
                </style>
            </head>
            <body>
                <h1>Каталог на Български Вина</h1>
                
                <table>
                    <thead>
                        <tr>
                            <th width="150">Снимка</th>
                            <th>Име на виното</th>
                            <th width="150">Цена</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="wineCatalog/wines/wine">
                            <xsl:sort select="name"/>
                            <tr>
                                <td align="center">
                                    <img class="wine-img">
                                        <xsl:attribute name="src">
                                            <xsl:value-of select="unparsed-entity-uri(image/@source)"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="alt">
                                            <xsl:value-of select="name"/>
                                        </xsl:attribute>
                                    </img>
                                </td>

                                <td>
                                    <h3 style="margin:0;"><xsl:value-of select="name"/></h3>
                                </td>

                                <td>
                                    <div class="price-tag">
                                        <xsl:value-of select="price"/> 
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="price/@currency"/>
                                    </div>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
                
                <p style="text-align:center; font-size:0.8em; color:#999; margin-top:30px;">
                    Генерирано чрез XSLT трансформация
                </p>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>