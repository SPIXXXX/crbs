# crbs

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

**Map Tiles / API Keys**

- **Why:** The app currently uses OpenStreetMap public tiles for development. Those public tile servers are rate-limited and intended for light/demo use only. For production apps you should use a commercial tile provider or self-host tiles.
- **Providers:** Common options are MapTiler (easy free tier), Mapbox (paid, feature-rich), Thunderforest, or self-hosted TileServer.

- **MapTiler (quick start):**
	1. Sign up at https://www.maptiler.com/ and create an API key.
	2. Replace the tile URL in your `flutter_map` `TileLayer` with:
		 `https://api.maptiler.com/tiles/streets/{z}/{x}/{y}.png?key=YOUR_KEY`
	3. Add attribution (follow provider rules):
		 `attributionBuilder: (_) => const Text('© MapTiler © OpenStreetMap contributors'),`

- **Mapbox (quick start):**
	1. Sign up at https://www.mapbox.com/ and get an access token.
	2. Use a Mapbox tiles/style URL in your `TileLayer`, for example:
		 `https://api.mapbox.com/styles/v1/{username}/{style_id}/tiles/256/{z}/{x}/{y}@2x?access_token=YOUR_TOKEN`

- **Where to store the key (do not commit keys):**
	- Web: create `web/api_key.js` (ignored by git) containing a single line:
		`window.__MAPS_API_KEY__ = 'YOUR_KEY';`
		Then load it from `web/index.html` or your app code. An example `web/api_key.example.js` is included.
	- Mobile (Android / iOS): use a build-time or runtime secret mechanism. Common approaches:
		- Use `flutter_dotenv` and a local `.env` file (do not commit `.env`).
		- Use platform-specific secure storage or CI secret injection.

- **Example `flutter_map` TileLayer (MapTiler):**

	TileLayer(
		urlTemplate: 'https://api.maptiler.com/tiles/streets/{z}/{x}/{y}.png?key=YOUR_KEY',
		userAgentPackageName: 'org.crbs.app',
		attributionBuilder: (_) => const Text('© MapTiler © OpenStreetMap contributors'),
	)

- **Follow terms & attribution:** Always follow the tile provider's terms of service and include required attribution. See OpenStreetMap tile policy: https://operations.osmfoundation.org/policies/tiles

If you want, I can update the app to use MapTiler and add a small helper to read the key from `web/api_key.js` and from `flutter_dotenv` for mobile — tell me which provider you prefer.
