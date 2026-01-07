//
//  WeatherService.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private let apiKey = "53009d6d90be74c2b32b28e418eca996"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchHongKongWeather(completion: @escaping (Result<WeatherData, Error>) -> Void) {
        // Coordinates for Hong Kong
        let lat = 22.3193
        let lon = 114.1694
        
        // Construct the URL
        let urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=zh_tw"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // Make the network request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                // Parse the JSON response
                let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
                
                // Convert to our WeatherData model
                let weatherData = WeatherData(
                    temperature: weatherResponse.main.temp,
                    feelsLike: weatherResponse.main.feels_like,
                    humidity: weatherResponse.main.humidity,
                    condition: weatherResponse.weather.first?.description ?? "未知",
                    windSpeed: weatherResponse.wind.speed * 3.6, // Convert m/s to km/h
                    rainfall: weatherResponse.rain?.oneHour ?? 0.0,
                    updateTime: Date(),
                    icon: weatherResponse.weather.first?.icon
                )
                
                DispatchQueue.main.async {
                    completion(.success(weatherData))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Mock data fallback for testing/development
    func fetchMockHongKongWeather(completion: @escaping (Result<WeatherData, Error>) -> Void) {
        // Simulate API call with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockWeather = WeatherData(
                temperature: Double.random(in: 20...30),
                feelsLike: Double.random(in: 22...32),
                humidity: Int.random(in: 60...90),
                condition: ["晴朗", "多雲", "有雨", "雷暴"].randomElement() ?? "晴朗",
                windSpeed: Double.random(in: 5...25),
                rainfall: Double.random(in: 0...10),
                updateTime: Date(),
                icon: ["01d", "02d", "03d", "04d", "09d", "10d", "11d"].randomElement()
            )
            completion(.success(mockWeather))
        }
    }
}

// MARK: - OpenWeatherMap API Response Models
struct OpenWeatherResponse: Codable {
    let main: MainWeatherData
    let weather: [WeatherInfo]
    let wind: WindData
    let rain: RainData?
    
    struct MainWeatherData: Codable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
    }
    
    struct WeatherInfo: Codable {
        let description: String
        let icon: String
    }
    
    struct WindData: Codable {
        let speed: Double // in m/s
    }
    
    struct RainData: Codable {
        let oneHour: Double?
        
        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
        }
    }
}
