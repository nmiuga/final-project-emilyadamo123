#  AI Prompt

Create a simple SwiftUI iOS app called **Travel Tracker**. The code should be beginner-friendly, well-organized, and include clear comments explaining each part.

---

## App Features

The app should allow users to:

- View a list of countries  
- Search for a country  
- Tap a country to see details  
- Save countries as:
  - “Been To”
  - “Want to Visit”

---

## API + Data

Use this API:

### Requirements:

- Create a `Country` model using `Codable`
- Include properties:
  - `name` (common)
  - `capital`
  - `population`
  - `region`
  - `flag` (image URL)
  - `cca2` (country code)

### ViewModel

Create a `ViewModel` (`ObservableObject`) that:

- Fetches data using `URLSession`
- Stores countries in a `@Published` array

---

## Views

### 1. Country List View

- Use a `NavigationStack`
- Display countries in a `List`

Each row should show:

- Country name  
- Flag image (use `AsyncImage`)  
- A button to save (Been / Want)

---

### 2. Detail View

Opens when a country is tapped.

Show:

- Country name (Title)  
- Flag image  
- Capital  
- Population  
- Region  

Include buttons to:

- Mark as “Been To”  
- Mark as “Want to Visit”

---

### 3. Search

- Add `.searchable()` to filter countries by name

---

## Layout + Design

- Use `ScrollView` and `VStack` where needed  
- Group content into simple sections (like cards)  
- Add padding and spacing  
- Use a clean layout that is easy to read  

---

## Text + Styling

Use at least:

- Title  
- Headline  
- Body text  

- Add a custom font (can be a placeholder)

---

## Images

- Use `AsyncImage` for flags  
- Style at least one image (rounded corners, shadow, etc.)

---

## Navigation + Filters

Add a simple filter (segmented control or buttons) to show:

- All countries  
- Been To  
- Want to Visit  

---

## Code Style

- Keep everything simple and easy to follow  
- Add comments explaining each section  
