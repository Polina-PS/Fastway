const express = require('express');
const app = express();
const mysql = require('mysql');
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'polinka',
    database: 'fastway'
});

app.set('view engine', 'ejs');
app.use(express.urlencoded({ extended: false }));
app.use(express.static('public'));

connection.connect((err) => {
    if (err) {
        console.error('Ошибка при подключении к базе данных:', err);
        return;
    }
    console.log('Успешное подключение к базе данных');
});

app.get('', (req, res) => {
    res.render('index');
});

app.get('/find', (req, res) => {
    res.render('find');
});

app.get('/passangers/:id_flight/:id_class/:name_class/:date_flight', (req, res) => {
    let { id_flight, id_class, name_class, date_flight } = req.params
    
    let sql = `SELECT * FROM Flight WHERE id_flight = ${id_flight}`
    
    connection.query(sql, (error, results) => {
        if (error || results.length === 0) {
            return res.status(404).send('Рейс не найден')
        } else {
            let sql_price = `CALL procedure_price_flight('${id_flight}', '${id_class}', @price);`
            let sql_seats = `CALL procedure_carriage_seat('${date_flight}', '${id_flight}', '${id_class}', @p3, @p4, @p5);`
            connection.query(sql_price, (error, results_price) => {
                if (error) {
                    return res.status(500).send('Ошибка при выполнении запроса к базе данных')
                }
                const price = results_price[0][0].price;
                connection.query(sql_seats, (error, results_seats) => {
                    console.log(results_seats)
                    const seat = results_seats[1][0].p_seat;
                    const carriage = results_seats[1][0].p_carriage
                
                    console.log('Место пассажира:' , seat, carriage)
    
                    res.render('passangers', { flight: results[0], id_class, name_class, price, seat, carriage, date_flight })
                })
                
            })
        }
    })
})

app.get('/success/:id_flight/:id_class/:date_flight/:last_name/:name/:father_name/:birthday/:series/:number/:phone/:mail', (req, res) => {
    let { id_flight, id_class, date_flight, last_name, name, father_name, birthday, series, number, phone, mail } = req.params;

    let sql_check_client = `SELECT * FROM Client WHERE last_name = '${last_name}' AND name = '${name}' AND father_name = '${father_name}'`;
    connection.query(sql_check_client, (error, results_check_client) => {
        if (error) {
            return res.status(500).send('Ошибка при выполнении запроса к базе данных');
        }
        if (results_check_client.length > 0) {
            let id_client = results_check_client[0].id_client;
            let sql_update_client = `UPDATE Client SET series = '${series}', number = '${number}', birthday = '${birthday}', mail = '${mail}', phone = '${phone}' WHERE id_client = ${id_client}`;
            connection.query(sql_update_client, (error, results_update_client) => {
                if (error) {
                    return res.status(500).send('Ошибка при выполнении запроса к базе данных');
                }
                insertTicket(id_client);
            });
        } else {
            let sql_insert_client = `INSERT INTO Client (name, last_name, father_name, series, number, birthday, mail, phone) VALUES ('${name}', '${last_name}', '${father_name}', '${series}', '${number}', '${birthday}', '${mail}', '${phone}')`;
            connection.query(sql_insert_client, (error, results_insert_client) => {
                if (error) {
                    return res.status(500).send('Ошибка при выполнении запроса к базе данных');
                }
                let id_client = results_insert_client.insertId;
                insertTicket(id_client);
            });
        }
    });

    function insertTicket(id_client) {
        let sql_check_ticket = `SELECT * FROM Ticket WHERE id_client = ${id_client} AND id_flight = ${id_flight} AND date_flight = '${date_flight}' AND id_class = ${id_class}`;
        connection.query(sql_check_ticket, (error, results_check_ticket) => {
            if (error) {
                return res.status(500).send('Ошибка при выполнении запроса к базе данных');
            }
            if (results_check_ticket.length === 0) {
                let sql_seats = `CALL procedura_count_main('${date_flight}', '${id_flight}', '${id_class}', @p3, @p4, @p5)`;
                connection.query(sql_seats, (error, results_seats) => {
                    if (error) {
                        return res.status(500).send('Ошибка при выполнении запроса к базе данных');
                    }
                    const seat = results_seats[1][0].p_seat;
                    const carriage = results_seats[1][0].p_carriage;
                    let sql_insert_ticket = `INSERT INTO Ticket (id_client, id_flight, date_flight, id_class, carriage, seat) VALUES (${id_client}, ${id_flight}, '${date_flight}', ${id_class}, ${carriage}, ${seat})`;
                    connection.query(sql_insert_ticket, (error, results_insert_ticket) => {
                        if (error) {
                            return res.status(500).send('Ошибка при выполнении запроса к базе данных');
                        }
                        res.render('success', { last_name, name, father_name, birthday, series, number, phone, mail, id_class,

seat, carriage, date_flight });
                    });
                });
            } else {
                res.send('Вы уже купили билет на этот рейс');
            }
        });
    }
});


app.post('/data_passangers/:id_flight/:id_class/:name_class/:date_flight/:carriage/:seat/:price', (req, res) => {
    let { last_name, name, father_name, birthday, series, number, phone, mail } = req.body;
    let { id_flight, id_class, name_class, date_flight, carriage, seat, price } = req.params;
    let dateArray = birthday.split('.');
    birthday = `${dateArray[2]}-${dateArray[1]}-${dateArray[0]}`;
    let sql = `SELECT * FROM Flight WHERE id_flight = ${id_flight}`;

    connection.query(sql, (error, results_flight) => {
        res.render('check', { last_name, name, father_name, birthday, series, number, phone, mail, flight: results_flight[0], id_class, name_class, price, seat, carriage, date_flight });
    });
});

app.post('/search_flights', (req, res) => {
    let { city1, city2, date_flight } = req.body;
    let dateArray = date_flight.split('.');
    date_flight = `${dateArray[2]}-${dateArray[1]}-${dateArray[0]}`;
    
    let sql = `SELECT * FROM Flight WHERE city_1 = '${city1}' AND city_2 = '${city2}'`;
    let sql_day = `SELECT * FROM Today WHERE day = '${date_flight}'`;

    connection.query(sql_day, (error, results_day) => {
        if (results_day.length === 0) {
            return res.render('index');
        } else {
            connection.query(sql, (error, results) => {
                if (error) {
                    return res.status(500).send('Ошибка при выполнении запроса к базе данных');
                } else if (results.length === 0) {
                    return res.render('index');
                } else {
                    const day_index = results_day[0].day_i;
                    const id_flights = results.map(result => result.id_flight);
                    const promises = [];

                    id_flights.forEach(id_flight => {
                        let sql_day_i = `SELECT ${day_index} as day_x, id_class, id_flight FROM Number_seats WHERE id_flight = '${id_flight}'`;
                        promises.push(new Promise((resolve, reject) => {
                            connection.query(sql_day_i, (error, results_day_i) => {
                                if (error) {
                                    reject(error);
                                } else {
                                    resolve({ id_flight, id_class: results_day_i.map(result => result.id_class), count_seats: results_day_i.map(result => result.day_x) });
                                }
                            });
                        }));
                    });

                    Promise.all(promises)
                        .then(data => {
                            const count_seats = data.map(item => item.count_seats);
                            const id_class = data.map(item => item.id_class);
                            res.render('find', { flights: results, day: results_day, day_index: day_index, id_class, count_seats, date_flight });
                        })
                        .catch(error => {
                            res.status(500).send('Ошибка при выполнении запроса к базе данных');
                        });
                }
            });
        }
    });
});







app.get('/sitemap', (req, res) => {
    res.render('sitemap');
});

app.get('/help', (req, res) => {
    res.render('help');
});

app.get('/station', (req, res) => {
    let sql_count_stations = 'SELECT City.id_city, City.name_city, COUNT(Station.id_station) AS station_count FROM Station INNER JOIN City ON Station.id_city = City.id_city GROUP BY City.name_city ORDER BY city.name_city';
    let sql_stations = 'SELECT name_station, id_city FROM Station';
    let sql_flight = "SELECT Flight.flight_number, Flight.time_way, Flight.time_start, Flight.time_end, Flight.number_train, Train_category.name_train_category, Flight.city_1, Flight.city_2, Flight.station_1, Flight.station_2 FROM Flight INNER JOIN Train ON Flight.number_train=Train.number_train INNER JOIN Train_category ON Train.id_train_category=Train_category.id_train_category";
    connection.query(sql_count_stations, (error, results_count) => {
        if (error) {
            console.error('Ошибка при запросе к базе данных:', error);
            return res.status(500).send('Ошибка при запросе к базе данных');
        } else {
            connection.query(sql_stations, (error, results_stations) => {
                if (error) {
                    console.error('Ошибка при запросе к базе данных:', error);
                    return res.status(500).send('Ошибка при запросе к базе данных');
                } else {
                    connection.query(sql_flight, (error, results_flight) => {
                        if (error) {
                            console.error('Ошибка при запросе к базе данных:', error);
                            return res.status(500).send('Ошибка при запросе к базе данных');
                        }
                        const flights_all = results_flight.map(flight => ({
                            flight_number: flight.flight_number,
                            time_way: flight.time_way,
                            time_start: flight.time_start,
                            time_end: flight.time_end,
                            number_train: flight.number_train,
                            name_train_category: flight.name_train_category,
                            city_1: flight.city_1,
                            city_2: flight.city_2,
                            station_1: flight.station_1,
                            station_2: flight.station_2
                        }));
                        res.render('station', {count_station: results_count, stationName: results_stations, flights_all: flights_all});
                    });
                }
            });
        }
    });
});

app.get('/station/city_:cityName', (req, res) => {
    const cityName = req.params.cityName;
    let sql_station_name = 'SELECT station.name_station FROM station JOIN city ON station.id_city = city.id_city WHERE city.name_city = ? ORDER BY station.name_station';
    connection.query(sql_station_name, [cityName], (err, results) => {
        if (err) {
            console.error('Ошибка при запросе данных из базы данных:', err);
            res.status(500).send('Ошибка при запросе данных из базы данных');
            return;
        }
            res.render('city', { cityName: cityName, stations: results });
    });
});

app.get('/station/city_:cityName/station_:stationName', (req, res) => {
    const cityName = req.params.cityName;
    const stationName = req.params.stationName;
    let sql_flight_station = "SELECT Flight.flight_number, Flight.time_way, Flight.time_start, Flight.time_end, Flight.number_train, Train_category.name_train_category, Flight.city_1, Flight.city_2, Flight.station_1, Flight.station_2 FROM Flight INNER JOIN Train ON Flight.number_train=Train.number_train INNER JOIN Train_category ON Train.id_train_category=Train_category.id_train_category WHERE Flight.station_1 = ? OR Flight.station_2 = ?";
    connection.query(sql_flight_station, [stationName, stationName], (err, results) => {
        if (err) {
            console.error('Ошибка при запросе данных из базы данных:', err);
            res.status(500).send('Ошибка при запросе данных из базы данных');
            return;
        }
        const flights = results.map(flight => ({
            flight_number: flight.flight_number,
            time_way: flight.time_way,
            time_start: flight.time_start,
            time_end: flight.time_end,
            number_train: flight.number_train,
            name_train_category: flight.name_train_category,
            city_1: flight.city_1,
            city_2: flight.city_2,
            station_1: flight.station_1,
            station_2: flight.station_2
        }));
        const flights_out = flights.filter(flight => flight.station_1 === stationName);
        const flights_in = flights.filter(flight => flight.station_2 === stationName);
        res.render('station_1', { cityName: cityName, stationName: stationName, flights_out: flights_out, flights_in: flights_in});
    });
});


const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Сервер запущен на http://localhost:${PORT}`);
});
