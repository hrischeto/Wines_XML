<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

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
                    
                    /* СТИЛОВЕ ЗА МЕНЮТО И ФИЛТРИТЕ */
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
                        margin-left: 15px;
                        margin-right: 5px;
                        font-weight: bold;
                    }
                    .menu select {
                        padding: 8px;
                        border-radius: 4px;
                        border: 1px solid #ccc;
                        margin-right: 15px;
                        cursor: pointer;
                    }
                    .review-btn {
                        background-color: #2c3e50;
                        color: white;
                        border: none;
                        padding: 6px 12px;
                        border-radius: 4px;
                        cursor: pointer;
                        font-size: 0.85em;
                        margin-top: 15px;
                        transition: background 0.3s;
                    }
                    .review-btn:hover {
                        background-color: #1a252f;
                    }
                    .review-container {
                        margin-top: 10px;
                        padding: 10px;
                        background-color: #fff9c4;
                        border-left: 4px solid #ff9800;
                        font-size: 0.9em;
                        display: none; /* Скрито по подразбиране */
                        border-radius: 0 4px 4px 0;
                    }
                    .review-item {
                        border-bottom: 1px solid #e0e0e0;
                        padding-bottom: 8px;
                        margin-bottom: 8px;
                    }
                    .review-item:last-child {
                        border-bottom: none;
                        margin-bottom: 0;
                    }
                    .review-user { font-weight: bold; color: #333; }
                    .review-stars { color: #ff9800; float: right;}
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

                    async function loadReviews(btn, wineId) {
                        let container = btn.nextElementSibling;

                        // Логика за скриване/показване
                        if (container.style.display === 'block') {
                            container.style.display = 'none';
                            btn.innerText = 'Виж мнения';
                            return;
                        }

                        btn.innerText = 'Зареждане...';

                        try {
                            // 1. Изтегляне на XML файла
                            const response = await fetch('reviews.xml');
                            if (!response.ok) throw new Error("Грешка при връзка");
    
                            const textData = await response.text();
                            const parser = new DOMParser();
                            const xmlDoc = parser.parseFromString(textData, "text/xml");
                            const allReviews = xmlDoc.querySelectorAll('review');
                            
                            let html = '';
                            let found = false;

                            allReviews.forEach(review => {
                                // Проверка дали ревюто е за текущото вино
                                if (review.getAttribute('wineId') === wineId) {
                                    found = true;
                                    
                                    // Извличане на данни от XML таговете
                                    let user = review.querySelector('user').textContent;
                                    let comment = review.querySelector('comment').textContent;
                                    let rating = parseInt(review.getAttribute('rating'));

                                    // Генериране на звезди
                                    let stars = '★'.repeat(rating) + '☆'.repeat(5 - rating);
                                    
                                    html += '<div class="review-item">';
                                    html += '<span class="review-user">' + user + '</span>';
                                    html += '<span class="review-stars">' + stars + '</span><br/>';
                                    html += '<i>"' + comment + '"</i>';
                                    html += '</div>';
                                }
                            });

                            if (found) {
                                container.innerHTML = html;
                            } else {
                                container.innerHTML = '<i>Няма добавени мнения за това вино.</i>';
                            }

                            container.style.display = 'block';
                            btn.innerText = 'Скрий мнения';

                        } catch (error) {
                            console.error(error);
                            container.innerHTML = 'Грешка: Не мога да заредя reviews.xml (проверете дали файлът съществува и дали ползвате локален сървър).';
                            container.style.display = 'block';
                            btn.innerText = 'Грешка';
                        }
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
                            
                            <br/>
                            <button class="review-btn" onclick="loadReviews(this, '{@wineId}')">
                                Виж мнения
                            </button>
                            <div class="review-container">
                                </div>
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