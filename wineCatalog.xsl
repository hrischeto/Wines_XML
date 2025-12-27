<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <!-- Keys -->
    <xsl:key name="regionLookup" match="region" use="@regionId"/>
    <xsl:key name="wineryLookup" match="winery" use="@wineryId"/>

    <xsl:template match="/">
        <html>
            <head>
                <title>Каталог на Български Вина</title>

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
                    h2 {
                        margin-top: 40px;
                        color: #722f37;
                    }
                    table {
                        width: 100%;
                        border-collapse: collapse;
                        background-color: white;
                        box-shadow: 0 0 10px rgba(0,0,0,0.1);
                        margin-top: 15px;
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
                        vertical-align: top;
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
                    }
                    .rating {
                        color: #ff9800;
                        font-weight: bold;
                    }
                    .meta-info {
                        font-size: 0.9em;
                        color: #666;
                    }
                    .menu {
                        text-align: center;
                        margin-bottom: 20px;
                    }
                    .menu button {
                        padding: 10px 20px;
                        margin: 5px;
                        border: none;
                        background-color: #722f37;
                        color: white;
                        cursor: pointer;
                        border-radius: 4px;
                    }
                    .menu button:hover {
                        background-color: #5a2228;
                    }
                    .menu label {
                        margin-left: 15px; /* Разстояние от предишния елемент */
                        margin-right: 5px; /* Разстояние до самото меню */
                        font-weight: bold;
                    }
                    .menu select {
                        padding: 8px;
                        border-radius: 4px;
                        border: 1px solid #ccc;
                        margin-right: 15px; /* Разстояние след менюто */
                        cursor: pointer;
                    }
                </style>

                <script>
                
                    function showSection(id) {
                        document.getElementById('allWines').style.display='none';
                        document.getElementById('byRegions').style.display='none';
                        document.getElementById('byWineries').style.display='none';
                        document.getElementById(id).style.display='block';
                    }

                    function getRows() {
                        return Array.from(
                            document.querySelectorAll('#allWines tbody tr')
                        );
                    }

                    function sortByPrice(order) {
                        let tbody = document.querySelector('#allWines tbody');
                        let rows = getRows();

                        rows.sort((a, b) => {
                            let p1 = parseFloat(a.dataset.price);
                            let p2 = parseFloat(b.dataset.price);
                            return order === 'asc' ? p1 - p2 : p2 - p1;
                        });

                        rows.forEach(r => tbody.appendChild(r));
                    }

                    function filterByType(type) {
                        getRows().forEach(row => {
                            row.style.display =
                                !type || row.dataset.type === type ? '' : 'none';
                        });
                    }

                    function filterByVintage(vintage) {
                        getRows().forEach(row => {
                            row.style.display =
                                !vintage || row.dataset.vintage === vintage ? '' : 'none';
                        });
                    }
                </script>
            </head>

            <body>
                <h1>Каталог на Български Вина</h1>

                <div class="menu">
                    <button onclick="showSection('allWines')">Всички вина (А-Я)</button>
                    <button onclick="showSection('byRegions')">По региони</button>
                    <button onclick="showSection('byWineries')">По изби</button>
                </div>

                <!-- ================= ALL WINES ================= -->
                <div id="allWines">

                    <div class="menu">
                        <label>Подреждане по цена:</label>
                        <select onchange="sortByPrice(this.value)">
                            <option value="">—</option>
                            <option value="asc">Възходящо</option>
                            <option value="desc">Низходящо</option>
                        </select>

                        <label>Тип вино:</label>
                        <select onchange="filterByType(this.value)">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(type=preceding::type)]">
                                <option>
                                    <xsl:value-of select="type"/>
                                </option>
                            </xsl:for-each>
                        </select>

                        <label>Реколта:</label>
                        <select onchange="filterByVintage(this.value)">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(vintage=preceding::vintage)]">
                                <xsl:sort select="vintage" data-type="number"/>
                                <option>
                                    <xsl:value-of select="vintage"/>
                                </option>
                            </xsl:for-each>
                        </select>
                    </div>

                    <xsl:call-template name="wineTable">
                        <xsl:with-param name="nodes" select="wineCatalog/wines/wine"/>
                    </xsl:call-template>
                </div>

                <!-- ================= BY REGIONS ================= -->
                <div id="byRegions" style="display:none;">
                    <xsl:for-each select="wineCatalog/regions/region">
                        <h2><xsl:value-of select="name"/></h2>

                        <xsl:variable name="rid" select="@regionId"/>
                        <xsl:call-template name="wineTable">
                            <xsl:with-param name="nodes"
                                select="/wineCatalog/wines/wine[@regionIdRef=$rid]"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </div>

                <!-- ================= BY WINERIES ================= -->
                <div id="byWineries" style="display:none;">
                    <xsl:for-each select="wineCatalog/wineries/winery">
                        <h2><xsl:value-of select="name"/></h2>

                        <xsl:variable name="wid" select="@wineryId"/>
                        <xsl:call-template name="wineTable">
                            <xsl:with-param name="nodes"
                                select="/wineCatalog/wines/wine[@wineryIdRef=$wid]"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </div>

            </body>
        </html>
    </xsl:template>

    <!-- ================= REUSABLE TABLE ================= -->
    <xsl:template name="wineTable">
        <xsl:param name="nodes"/>

        <table>
            <thead>
                <tr>
                    <th width="120">Снимка</th>
                    <th width="25%">Вино &amp; Характеристики</th>
                    <th width="20%">Произход</th>
                    <th>Описание на Сомелиера</th>
                    <th width="10%">Цена &amp; Рейтинг</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="$nodes">
                    <xsl:sort select="name"/>
                    <tr data-price="{price}" data-type="{type}" data-vintage="{vintage}">
                        <td align="center">
                            <img class="wine-img"
                                 src="{unparsed-entity-uri(image/@source)}"/>
                        </td>
                        <td>
                            <strong><xsl:value-of select="name"/></strong><br/>
                            <span class="meta-info">
                                Тип: <xsl:value-of select="type"/> |
                                Реколта: <xsl:value-of select="vintage"/>
                            </span>
                        </td>
                        <td class="meta-info">
                            Изба:
                            <xsl:value-of select="key('wineryLookup', @wineryIdRef)/name"/><br/>
                            Регион:
                            <xsl:value-of select="key('regionLookup', @regionIdRef)/name"/>
                        </td>
                        <td>
                            <xsl:value-of select="sommelierDescription"/>
                        </td>
                        <td>
                            <div class="price-tag">
                                <xsl:value-of select="price"/> 
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="price/@currency"/>
                            </div>
                            <br/>
                            <div class="rating">
                                Рейтинг: <xsl:value-of select="rating"/>
                            </div>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>

</xsl:stylesheet>
