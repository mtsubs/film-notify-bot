# Film Notify Bot

**[中文](./README.md) | English**

**Film Notify Bot** is a Telegram bot that tracks new digital movie releases and sends structured updates. It automatically shares movie titles, ratings, and platform information directly to your Telegram channel or group.

## Why We Developed It

MontageSubs (蒙太奇字幕组) is an independent volunteer team dedicated to delivering high-quality Chinese subtitles for carefully selected films and series. Film Notify Bot helps subtitle teams by providing timely information on new digital releases, supporting decisions about which movies to translate and subtitle.

## Features
- Fetch daily lists of new digital releases filtered by IMDb ratings
- Retrieve detailed movie information from TMDB (titles, release year, synopsis, genre, duration, production company, online platforms)
- Include ratings from IMDb, Letterboxd, Metacritic, and RogerEbert
- Format messages into structured, readable text for Telegram
- Maintain a deduplication file (`sent_tmdb_ids.txt`) to prevent repeated notifications

## Official Channel & Bot

- Telegram Channel: [@FilmNotify](https://t.me/+3drwnBP0yjszMmNh)  
- Telegram Bot: [@FilmNotifyBot](https://t.me/FilmNotifyBot)  

Currently, the bot sends notifications in Chinese only. It runs exclusively in designated channels and is not a public service at this time. If you’d like support for your language, feel free to open an Issue. We welcome all requests and will evaluate language support accordingly.

## Self-Hosting & Deployment

The bot can be deployed on local/private servers or run automatically via GitHub Actions for daily monitoring. For full setup instructions, API configuration, and environment variables, see [DEPLOYMENT.en.md](./DEPLOYMENT.en.md).

## Acknowledgements

Special thanks to [MDBList](https://mdblist.com/) and [TMDB](https://www.themoviedb.org/) for their services and APIs.

We also appreciate GitHub for providing infrastructure and automation, enabling stable hosting and reliable bot operation.

## Community

Join our community to discuss subtitles, movies, give feedback, or contribute:
- **Telegram**: [MontageSubs](https://t.me/+HCWwtDjbTBNlM2M5)  
- **IRC**: [#MontageSubs](https://web.libera.chat/#MontageSubs) (synced with Telegram)

## License

The source code and documentation in this repository (unless otherwise noted) are licensed under the [MIT License](./LICENSE) by **MontageSubs**.

---

<div align="center">

**MontageSubs (蒙太奇字幕组)**  
“Powered by love ❤️ 用爱发电”

</div>
