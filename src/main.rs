use std::{
    env::current_dir,
    ffi::OsStr,
    fs::{read_dir, remove_dir_all, remove_file},
    io::Result,
    os::unix::ffi::OsStrExt,
    path::Path,
    process::Command,
};

fn main() -> Result<()> {
    iter_dir(&current_dir()?)
}

fn iter_dir(path: &Path) -> Result<()> {
    for entry in read_dir(path)? {
        let entry = entry?;
        let file_type = entry.file_type()?;
        let name = entry.file_name();
        if name == OsStr::new("flake.lock") && file_type.is_file() {
            println!("found flake at {}", entry.path().display());
            Command::new("nix")
                .arg("flake")
                .arg("update")
                .current_dir(path)
                .spawn()?
                .wait()?;
        } else if file_type.is_dir() {
            if name == OsStr::new(".direnv") {
                let path = entry.path();
                println!("found direnv dir at {}", path.display());
                remove_dir_all(&path)?;
            } else if name == OsStr::new("node_modules") {
            } else if !name.is_empty() && name.as_bytes()[0] != b'.' {
                iter_dir(&entry.path())?;
            }
        } else if file_type.is_symlink() && name == OsStr::new("result") {
            let path = entry.path();
            println!("found result symlink at {}", path.display());
            remove_file(&path)?;
        }
    }
    Ok(())
}
