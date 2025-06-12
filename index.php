<?php
error_log("Proba de erro forzada en index.php");
# Conexión á base de datos coa IP do host
$servername = "192.168.18.247";
$username = "web";
$password = "contrasinal";
$dbname = "hostEZ";

try {
    # Intentar conectar á base de datos
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    # Obter todas as versións da táboa VERSION
    $sql_versions = "SELECT DISTINCT minecraft_version FROM VERSION";
    $result_versions = $conn->query($sql_versions);
    $versions = [];
    if ($result_versions->rowCount() > 0) {
        while ($row = $result_versions->fetch(PDO::FETCH_ASSOC)) {
            $versions[] = $row['minecraft_version'];
        }
    }

    # Obter todos os mods por loader e versión
    $fabric_mods = [];
    $selected_version = isset($_GET['version']) ? $_GET['version'] : (isset($versions[0]) ? $versions[0] : '');
    $sql_mods = "SELECT m.name, m.description, mv.loader, mv.minecraft_version 
                 FROM MODS m
                 JOIN MOD_VERSION mv ON m.modID = mv.modID
                 WHERE mv.minecraft_version = :version
                 AND m.loader != 'de'";
    $stmt = $conn->prepare($sql_mods);
    $stmt->bindParam(':version', $selected_version);
    $stmt->execute();
    $mods = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($mods as $mod) {
        if ($mod['loader'] == 'fa') {
            $fabric_mods[$mod['name']] = $mod['description'];
        }
    }

    $conn = null; # Pechar a conexión
} catch (PDOException $e) {
    error_log("Erro de conexión: " . $e->getMessage());
    die("Erro: Non se pode conectar á base de datos. Consulta os logs para máis detalles.");
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>hostEZ</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="container">
    <header>
      <div class="logo-container">
        <img src="img/LOGO.png" alt="hostEZ Logo" class="logo">
      </div>
      <h1>Hosting</h1>
      <h1>made easy</h1>
    </header>
    <form action="save_csv.php" method="post" id="serverForm">
      <h3>Datos do cliente:</h3>
      <br>
      <label for="username">Nome de usuario:</label>
      <input type="text" id="username" name="username" required>
      <br>
      <label for="email">email:</label>
      <input type="text" id="email" name="email" required>
      <br>
      <label for="contact_phone">Teléfono:</label>
      <input type="text" id="contact_phone" name="contact_phone" required>
      <br>
      <label for="billing_address">Enderezo de facturación:</label>
      <input type="text" id="billing_address" name="billing_address" required>
      <br>
      <h3>Specs do servidor:</h3>
      <label for="cpus">CPUs:</label>
      <select id="cpus" name="cpus">
        <option value="1">1</option>
        <option value="2">2</option>
        <option value="4">4</option>
      </select>
      <br>
      <label for="ram">RAM (GB):</label>
      <select id="ram" name="ram">
        <option value="1024">1</option>
        <option value="2048">2</option>
        <option value="4096">4</option>
        <option value="8192">8</option>
      </select>
      <br>
      <label for="name">Nome:</label>
      <input type="text" id="name" name="name" required>
      <br>
      <h3>Información interna do servidor:</h3>
      <label for="version">Versión:</label>
      <select id="version" name="version" class="custom-select">
        <?php foreach ($versions as $version): ?>
          <option value="<?php echo $version; ?>" <?php echo $version == $selected_version ? 'selected' : ''; ?>><?php echo $version; ?></option>
        <?php endforeach; ?>
      </select>
      <br>
      <label>Loader:</label>
      <br>
      <div class="loader-options">
        <input type="radio" id="fabric" name="loader" value="Fabric" checked>
        <label for="fabric">Fabric</label>
        <input type="radio" id="forge" name="loader" value="Forge" disabled>
        <label for="forge">Forge</label>
      </div>
      <br>
      <div id="modSections">
        <div class="mod-section" id="fabricMods">
          <h4>Fabric Mods</h4>
          <?php foreach ($fabric_mods as $mod => $description): ?>
            <div class="mod-item">
              <input type="checkbox" name="mods[]" value="<?php echo $mod; ?>" id="fab_<?php echo htmlspecialchars($mod); ?>" <?php echo $mod === 'Fabric API' ? 'checked' : ''; ?>>
              <label for="fab_<?php echo htmlspecialchars($mod); ?>" class="mod-label"><?php echo $mod; ?></label>
              <div class="mod-description"><?php echo htmlspecialchars($description); ?></div>
            </div>
            <br>
          <?php endforeach; ?>
        </div>
      </div>
      <br>
      <button type="submit">Submit</button>
    </form>
    <div id="message" style="color: white;"></div>
  </div>
  <script src="js/script.js"></script>
</body>
</html>